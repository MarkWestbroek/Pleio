# Login Workaround (lokale ontwikkeling)

## Probleem
Op `http://test1.pleio.local:8000/` werkte login/register niet goed in local:
- OIDC gaf `Client ID Error` (ongeldige `client_id` bij `account.pleio-test.nl`)
- Registreren logde wel in, maar zonder adminrechten

## Root cause
De lokale `backend2/.env` wees naar een externe OIDC-provider met een client die in deze lokale context niet geldig was.

## Oplossing
Er is een **local-only login fallback** toegevoegd in de backend-auth views.

### Aangepast bestand
- `backend2/core/views/authentication.py`

### Wijzigingen in dat bestand
1. Local helper toegevoegd om een lokale gebruiker te maken/halen:
   - `_local_dev_user(request, mode="login")`
2. Local helper toegevoegd om die gebruiker direct in te loggen:
   - `_local_dev_login(request, mode="login")`
3. In `register(request)`:
   - Als `settings.ENV == "local"` -> direct local login flow (`mode="register"`)
4. In `login(request)`:
   - Als `settings.ENV == "local"` -> direct local login flow (`mode="login"`)
5. Adminrechten afgedwongen voor local login:
   - Bij `mode="login"` wordt gebruiker promoted naar `is_superadmin=True`
   - `suspend_admin_privileges=False` wordt hersteld indien nodig

## Gedrag na fix
- `/login` werkt lokaal zonder externe OIDC-redirect en geeft adminrechten
- `/register` werkt lokaal en logt direct in (niet per se admin)

## Verificatie
Getest via GraphQL `viewer` query na `/login`:
- `loggedIn = true`
- `isAdmin = true`
- user: `admin@local.test`

## Handige URLs
- Login (admin lokaal): `http://test1.pleio.local:8000/login`
- Register (lokale gebruiker): `http://test1.pleio.local:8000/register`
- Logout: `http://test1.pleio.local:8000/logout`

## Opmerking
Deze workaround is bewust beperkt tot `ENV=local` en heeft geen effect op niet-lokale omgevingen.

## Rollback (workaround uitzetten)
Als je weer volledig via OIDC wilt inloggen in local:

1. Verwijder in `backend2/core/views/authentication.py` de `settings.ENV == "local"` shortcuts in:
   - `login(request)`
   - `register(request)`
2. Verwijder de helperfuncties:
   - `_local_dev_user(...)`
   - `_local_dev_login(...)`
3. Herstart de stack:
   - `Pleio: Stop`
   - `Pleio: Start`
4. Controleer dat `/login` weer doorstuurt naar OIDC (`/oidc/authenticate/...`).

Optioneel: houd de code staan en zet een extra feature-flag in (bijv. env var) om de local bypass expliciet aan/uit te schakelen.
