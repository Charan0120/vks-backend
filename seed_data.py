"""
Seed script to populate initial data for the VKS Creative Skill Academy.
Run with: python manage.py shell < seed_data.py
"""
import os
import django

# Bootstrap Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'vks_backend.settings')
django.setup()

from users.models import User
from courses.models import Course

print("🌱 Seeding VKS Creative Skill Academy database...")

# ─── Admin User ──────────────────────────────────────────────────────────────
admin_email = os.environ.get('DJANGO_SUPERUSER_EMAIL', os.environ.get('ADMIN_EMAIL', 'admin@vks-sharanyango.org.in')).strip()
admin_password = os.environ.get('DJANGO_SUPERUSER_PASSWORD', os.environ.get('ADMIN_PASSWORD', 'VKSAdmin@2024!')).strip()
admin_username = os.environ.get('DJANGO_SUPERUSER_USERNAME', os.environ.get('ADMIN_USERNAME', admin_email.split('@')[0])).strip()

admin, created = User.objects.get_or_create(
    email=admin_email,
    defaults={
        'username': admin_username,
        'first_name': 'Admin',
        'last_name': 'User',
        'phone': '09769228347',
        'role': User.Role.ADMIN,
        'centre': User.Centre.ALL,
        'is_staff': True,
        'is_superuser': True,
    }
)
admin.set_password(admin_password)
admin.is_staff = True
admin.is_superuser = True
admin.role = User.Role.ADMIN
admin.save()
print(f"  ✓ Admin user ready: {admin_email}")

# ─── Courses ─────────────────────────────────────────────────────────────────
courses_data = [
    {'code': 'SE-01', 'title': 'Spoken English', 'description': 'Improve spoken English communication skills for personal and professional growth.', 'duration_months': 3},
    {'code': 'PD-01', 'title': 'Personal Development', 'description': 'Build confidence, interpersonal skills, and personality traits for success.', 'duration_months': 2},
    {'code': 'CC-01', 'title': 'Computer Classes', 'description': 'Basic to intermediate computer skills, MS Office, internet, and digital literacy.', 'duration_months': 3},
    {'code': 'CR-01', 'title': 'Crash Course - English', 'description': 'Short intensive English language training for quick skill development.', 'duration_months': 1},
    {'code': 'DIP-01', 'title': 'Diploma in Computer Applications', 'description': 'Full diploma covering computer fundamentals, software applications, and programming basics.', 'duration_months': 12},
    {'code': 'DEG-01', 'title': 'Degree Programme', 'description': 'Partner degree programme for continuing students.', 'duration_months': 36},
    {'code': 'SHL-01', 'title': 'Skill Development Training', 'description': 'Employability and vocational skills training for youth and women.', 'duration_months': 2},
]
for c in courses_data:
    obj, created = Course.objects.get_or_create(code=c['code'], defaults=c)
    status = "created" if created else "exists"
    print(f"  ✓ Course {status}: {obj.title}")

print("\n✅ Seeding complete! VKS Creative Skill Academy database is populated.")
print("   Admin Login: admin@vks-sharanyango.org.in / VKSAdmin@2024!")
