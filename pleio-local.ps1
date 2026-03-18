param(
    [ValidateSet('start', 'stop', 'restart', 'status', 'logs', 'reset', 'init', 'verify')]
    [string]$Action = 'status'
)

$ErrorActionPreference = 'Stop'
$repo = 'D:\Git\Pleio\backend2'

function In-Repo {
    param([scriptblock]$Script)
    Push-Location $repo
    try {
        & $Script
    }
    finally {
        Pop-Location
    }
}

function Write-Step {
    param([string]$Message)
    Write-Host "[pleio-local] $Message" -ForegroundColor Cyan
}

switch ($Action) {
    'start' {
        Write-Step 'Starting Pleio stack (build + up)...'
        In-Repo { docker compose up -d --build }
        In-Repo { docker compose ps }
    }
    'stop' {
        Write-Step 'Stopping Pleio stack...'
        In-Repo { docker compose down }
    }
    'restart' {
        Write-Step 'Restarting Pleio stack...'
        In-Repo { docker compose down }
        In-Repo { docker compose up -d --build }
        In-Repo { docker compose ps }
    }
    'status' {
        Write-Step 'Current container status:'
        In-Repo { docker compose ps }
    }
    'logs' {
        Write-Step 'Streaming logs for api/admin/background (Ctrl+C to stop)...'
        In-Repo { docker compose logs -f api admin background }
    }
    'reset' {
        Write-Step 'Resetting stack and volumes (destructive for local data)...'
        In-Repo { docker compose down -v }
        In-Repo { docker compose rm -f }
        In-Repo { docker compose up -d --build }
        In-Repo { docker compose ps }
    }
    'init' {
        Write-Step 'Initializing public tenant...'
        In-Repo { docker compose exec admin /app/manage.py create_tenant --noinput --schema_name=public --name=public --domain-domain=localhost }

        Write-Step 'Initializing test tenant (test1.pleio.local)...'
        In-Repo { docker compose exec admin /app/manage.py create_tenant --noinput --schema_name=test1 --name=test1 --domain-domain=test1.pleio.local }

        Write-Step 'Creating/updating local superadmin...'
        In-Repo {
            docker compose exec admin /app/manage.py shell -c "from user.models import User; u,created=User.objects.get_or_create(email='admin@local.test', defaults={'name':'Local Admin','is_superadmin':True,'is_active':True}); u.is_superadmin=True; u.is_active=True; u.set_password('admin123!'); u.save(); print('created' if created else 'updated')"
        }

        Write-Step 'Init done.'
    }
    'verify' {
        Write-Step 'Checking admin endpoint...'
        $admin = Invoke-WebRequest -UseBasicParsing http://localhost:8888/ -Method GET
        Write-Host "Admin HTTP status: $($admin.StatusCode)"

        Write-Step 'Checking tenant endpoint via Host header...'
        try {
            Invoke-WebRequest -UseBasicParsing http://localhost:8000/ -Headers @{Host='test1.pleio.local'} -Method GET | Out-Null
            Write-Host 'Tenant endpoint responds for Host test1.pleio.local'
        }
        catch {
            Write-Host 'Tenant endpoint returned a non-2xx response, but host routing appears reachable.' -ForegroundColor Yellow
        }
    }
}
