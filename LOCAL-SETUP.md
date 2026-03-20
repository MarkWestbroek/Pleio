# Pleio lokaal op Windows

Deze runbook is afgestemd op de huidige setup in deze workspace:
- backend repo: D:/Git/Pleio/backend2
- frontend repo: D:/Git/Pleio/frontend

## Snelle start

1. Start Docker Desktop.
2. Start de stack:

```powershell
cd D:\Git\Pleio\backend2
docker compose up -d --build
```

3. Open:
- Admin/control: http://localhost:8888
- Tenant (na hosts entry): http://test1.pleio.local:8000

## Dagstart morgen

Gebruik normaal deze volgorde:

1. Start Docker Desktop.
2. Wacht tot Docker volledig klaar is.
3. Start in VS Code de run/debug-config of taak:
	- Pleio: Start + Verify
4. Open daarna:
	- http://localhost:8888
	- http://test1.pleio.local:8000

Praktisch:
- Als de containers nog draaien: alleen Pleio: Verify.
- Als Docker of de stack uit stond: Pleio: Start + Verify.
- Als de site vreemd doet: eerst Pleio: Stop, daarna Pleio: Start + Verify.

Opmerking over frontend assets:
- De `frontend` Docker-container is **uitgeschakeld** (niet meer in `COMPOSE_PROFILES`). Die container overschreef bij elke start de runtime-assets met een externe image die niet aansluit op de lokale backend.
- Gebruik altijd de lokale Vite dev server (zie "Frontend lokaal met Vite" hieronder). Dat is de enige correcte frontend-bron zolang je lokaal ontwikkelt.
- `FRONTEND_LIVE_RELOAD=True` staat in `.env`, zodat de backend-templates rechtstreeks naar `http://localhost:9001` wijzen in plaats van statische bundles te laden.

## Als het weer misgaat

Gebruik deze korte checklist:

1. Draait Docker Desktop echt volledig?
2. Draait de stack?
	- Gebruik Pleio: Verify
3. Werkt admin wel, maar tenant niet?
	- Test http://localhost:8888
	- Test http://test1.pleio.local:8000
4. Witte pagina of kapotte widgets/custom pagina's?
	- Doe een harde refresh in de browser met Ctrl+F5
	- Herstart met Pleio: Stop en daarna Pleio: Start + Verify
5. Login werkt vreemd?
	- Ga naar /logout en daarna opnieuw naar /login
	- In local hoort /login direct als admin in te loggen
6. Nog steeds frontend-achtige fouten of GraphQL-mismatches?
	- Draait de lokale Vite dev server (`corepack yarn dev` in `D:/Git/Pleio/frontend`)?
	- Controleer dat `FRONTEND_LIVE_RELOAD=True` en `COMPOSE_PROFILES=base,admin` in `backend2/.env` staan.
	- De frontend Docker-container is uitgeschakeld; die was de oorzaak van versie-mismatches.

## Dagelijkse commando's

## VS Code one-click taken

In deze workspace staat nu een tasks-config in `.vscode/tasks.json`.

Open in VS Code:
1. Terminal > Run Task
2. Kies een taak, bijvoorbeeld:
	- Pleio: Start
	- Pleio: Stop
	- Pleio: Status
	- Pleio: Logs
	- Pleio: Verify
	- Pleio: Init
	- Pleio: Reset (destructive)

Alle taken gebruiken intern het script `pleio-local.ps1` met `-ExecutionPolicy Bypass`, zodat de standaard PowerShell policy op deze machine geen blokkade vormt.

## VS Code Run and Debug knoppen

In deze workspace staat nu ook een debug launch-config in `.vscode/launch.json`.

Open in VS Code:
1. Run and Debug (Ctrl+Shift+D)
2. Kies een configuratie en klik op start:
	- Pleio: Stop + Start + Verify
	- Pleio: Start + Verify
	- Pleio: Start
	- Pleio: Verify
	- Pleio: Logs
	- Pleio: Stop

Deze knoppen starten hetzelfde `pleio-local.ps1` script als de taken, ook met `-ExecutionPolicy Bypass`.

### Status

```powershell
cd D:\Git\Pleio\backend2
docker compose ps
```

### Logs

```powershell
cd D:\Git\Pleio\backend2
docker compose logs -f api admin background
```

### Stop

```powershell
cd D:\Git\Pleio\backend2
docker compose down
```

### Volledige reset (let op: verwijdert volumes/data)

```powershell
cd D:\Git\Pleio\backend2
docker compose down -v
docker compose rm -f
docker compose up -d --build
```

## Init van lokale tenant en admin

Deze setup is al uitgevoerd, maar hieronder staat het opnieuw voor een schone herstart.

### Public tenant

```powershell
cd D:\Git\Pleio\backend2
docker compose exec admin /app/manage.py create_tenant --noinput --schema_name=public --name=public --domain-domain=localhost
```

### Voorbeeld tenant

```powershell
cd D:\Git\Pleio\backend2
docker compose exec admin /app/manage.py create_tenant --noinput --schema_name=test1 --name=test1 --domain-domain=test1.pleio.local
```

### Admin gebruiker

```powershell
cd D:\Git\Pleio\backend2
docker compose exec admin /app/manage.py shell -c "from user.models import User; u,created=User.objects.get_or_create(email='admin@local.test', defaults={'name':'Local Admin','is_superadmin':True,'is_active':True}); u.is_superadmin=True; u.is_active=True; u.set_password('admin123!'); u.save(); print('created' if created else 'updated')"
```

## Hosts file (vereist Administrator)

Voeg deze regel toe aan:
C:/Windows/System32/drivers/etc/hosts

```text
127.0.0.1 test1.pleio.local
```

## Frontend lokaal met Vite (vereist voor ontwikkeling)

De frontend Docker-container is uitgeschakeld. Start altijd de lokale Vite dev server:

1. Configureer frontend token volgens frontend README (.npmrc met tiptap token).
2. Installeer dependencies in D:/Git/Pleio/frontend.
3. Start frontend dev server:

```powershell
cd D:\Git\Pleio\frontend
corepack yarn dev
```

4. Herstart backend stack zodat backend de lokale frontend op poort 9001 detecteert.

## Troubleshooting (Windows)

1. Docker daemon niet bereikbaar
- Symptoom: failed to connect to dockerDesktopLinuxEngine.
- Oplossing: start Docker Desktop en wacht tot docker info werkt.

2. CRLF shebang fout in containers
- Symptoom: /usr/bin/env: 'bash\r' of 'python\r'.
- Oplossing: zet line endings naar LF voor scripts zoals docker/*.sh en manage.py, daarna docker compose up -d --build.

3. npm.ps1 geblokkeerd door execution policy
- Symptoom: npm.ps1 cannot be loaded because running scripts is disabled.
- Oplossing: gebruik npm.cmd of corepack/yarn i.p.v. npm.ps1.

4. test1.pleio.local opent niet
- Controleer hosts-file entry (admin rechten nodig).
- Test met Host-header:

```powershell
Invoke-WebRequest -UseBasicParsing http://localhost:8000/ -Headers @{Host='test1.pleio.local'}
```

5. Veel compose waarschuwingen over env vars
- In deze lokale setup zijn diverse lege variabelen informatief en niet blocker.

## Belangrijke configuratiepunten

Voor een volledig overzicht van harde/lokale configuratie-opties, zie:
- [configuratie.md](configuratie.md)

Samenvatting:
- Custom content types in tenant-admin hangen af van `CUSTOM_CONTENT_TYPE_ENABLED`.
- In deze lokale setup is een login-workaround actief in `ENV=local`.
- OIDC-variabelen in `backend2/.env` bepalen externe loginflow.
- `localhost:8888` (control/admin app) en `test1.pleio.local:8000` (tenant app) hebben verschillende rollen.

# Workaround login
Voor deze lokale setup heb je nu geen wachtwoord meer nodig voor de site-login.

Gebruik:

Inloggen: ga naar http://test1.pleio.local:8000/login
Registreren: ga naar http://test1.pleio.local:8000/register
Standaard logt /login je in als:

e-mail: admin@local.test
naam: Local admin
Wil je een specifieke gebruiker:

http://test1.pleio.local:8000/login?email=jij@local.test&name=Jouw%20Naam
of via register: http://test1.pleio.local:8000/register?email=jij@local.test&name=Jouw%20Naam
Voor de admin op http://localhost:8888 blijft de eerder ingestelde account geldig:

e-mail: admin@local.test
wachtwoord: admin123!

Gefixt. Je had gelijk: /login gaf wel sessie, maar niet altijd adminrechten.

Ik heb het aangepast in authentication.py, zodat in lokale omgeving (ENV=local) een login-gebruiker altijd naar superadmin wordt gezet.

Gevalideerd:

viewer.loggedIn = true
viewer.isAdmin = true
gebruiker: admin@local.test
Gebruik nu gewoon:

http://test1.pleio.local:8000/login
Als je al ingelogd bent met een non-admin account, doe eerst:

http://test1.pleio.local:8000/logout
daarna opnieuw http://test1.pleio.local:8000/login
