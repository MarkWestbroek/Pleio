# Configuratie-overzicht (lokale setup)

Dit document beschrijft de harde configuratie-opties die in deze lokale omgeving relevant zijn, inclusief waar ze staan en wat het effect is.

## 1. Custom content types feature flag

Naam
- CUSTOM_CONTENT_TYPE_ENABLED

Waar gedefinieerd
- backend2/core/base_config.py

Default
- False

Effect
- Bepaalt of Nieuwe contenttypes beschikbaar is in tenant-admin.
- Route en menu-item voor Content > Types worden alleen getoond als deze op True staat.

Waar gebruikt
- backend2/core/resolvers/types/site_settings.py
  - resolver isCustomContentTypeEnabled
- frontend/src/js/admin/Routes.jsx
- frontend/src/js/admin/lib/useMenu.jsx

Wijzigen via Control app (aanbevolen)
- Open control admin op localhost:8888
- Ga naar Site > Profile > Optional features
- Zet Enable custom content types aan

Wijzigen via shell (alternatief)
- In tenant-context van test1: config.CUSTOM_CONTENT_TYPE_ENABLED = True

---

## 2. Lokale login workaround (zonder externe OIDC)

Naam
- Local login/register fallback op ENV local

Waar geconfigureerd
- backend2/core/views/authentication.py

Trigger
- settings.ENV == local

Effect
- Login en register gebruiken lokale flow in plaats van externe OIDC redirect.
- /login logt lokaal direct in.
- In local login-flow wordt gebruiker promoted naar superadmin.

Waarom toegevoegd
- Externe OIDC client op account.pleio-test.nl gaf Client ID Error voor lokale callback URL/client.

Rollback
- Verwijder de local shortcuts in login() en register()
- Verwijder helpers _local_dev_user en _local_dev_login
- Herstart stack

---

## 3. OIDC instellingen in lokale env

Bestand
- backend2/.env

Belangrijke variabelen
- OIDC_RP_CLIENT_ID
- OIDC_RP_CLIENT_SECRET
- OIDC_OP_AUTHORIZATION_ENDPOINT
- OIDC_OP_TOKEN_ENDPOINT
- OIDC_OP_USER_ENDPOINT
- OIDC_OP_LOGOUT_ENDPOINT

Effect
- Stuurt standaard login naar externe account provider.
- Onjuiste of niet-geregistreerde client_id/redirect_uri veroorzaakt loginfouten.

Opmerking
- In deze setup wordt dit tijdelijk omzeild door de lokale login workaround (punt 2).

---

## 4. Admin app versus tenant app

Naam
- RUN_AS_ADMIN_APP

Waar gebruikt
- backend2/backend2/settings.py
- backend service admin in docker-compose draait met RUN_AS_ADMIN_APP True

Effect
- localhost:8888 draait control/admin app (beheer van sites en profielinstellingen)
- test1.pleio.local:8000 draait tenant app (eindgebruikers + tenant-admin frontend)

Gevolg voor beheer
- Sommige feature toggles (zoals custom content types) zet je in control/admin, niet in de tenant contentlijst.

---

## 5. Frontend assets en manifestgedrag

Bestanden
- backend2/core/templatetags/vite.py
- backend2/docker/start-dev.sh
- backend2/docker-compose.yml

Relevante punten
- Vite manifest bepaalt welke frontend bundles geladen worden.
- Bij ontbreken van manifest is er fallback op legacy assets.
- Na frontend build in frontend map moeten assets naar static-frontend en daarna collectstatic.

Praktisch
- Na assetwissels kan api restart nodig zijn zodat manifest-cache wordt ververst.

---

## Snelcheck voor huidige status

- Ingelogd als admin op tenant: viewer.isAdmin moet True zijn
- Custom content types aan: site.isCustomContentTypeEnabled moet True zijn
- Menu-item zichtbaar: Admin > Content > Types
