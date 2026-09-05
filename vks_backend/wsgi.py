import os
import sys
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'vks_backend.settings')

application = get_wsgi_application()

# Auto-migrate database on server boot to ensure all PostgreSQL tables/columns are created
try:
    from django.core.management import call_command
    print("Running database migrations on startup...", file=sys.stderr)
    call_command('migrate', interactive=False)
    print("Database migrations completed successfully.", file=sys.stderr)
except Exception as e:
    print(f"Startup migration notice: {e}", file=sys.stderr)

