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
admin, created = User.objects.get_or_create(
    email='admin@vks-sharanyango.org.in',
    defaults={
        'username': 'admin',
        'first_name': 'Veena',
        'last_name': 'Prakash',
        'phone': '09769228347',
        'role': User.Role.ADMIN,
        'centre': User.Centre.ALL,
        'is_staff': True,
        'is_superuser': True,
    }
)
if created:
    admin.set_password('VKSAdmin@2024!')
    admin.save()
    print("  ✓ Admin user created: admin@vks-sharanyango.org.in")
else:
    print("  ✓ Admin user already exists.")

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
