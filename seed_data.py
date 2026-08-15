"""
Seed script to populate initial data for the VKS Sharanya database.
Run with: python manage.py shell < seed_data.py
"""
import os
import sys
import django

# Bootstrap Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'vks_backend.settings')
django.setup()

from users.models import User
from courses.models import Course
from activities.models import Project, Activity
from notifications.models import Notification

print("🌱 Seeding VKS Sharanya database...")

# ─── Admin User ──────────────────────────────────────────────────────────────
admin, created = User.objects.get_or_create(
    email='admin@vks-sharanyango.org.in',
    defaults={
        'username': 'admin',
        'first_name': 'Veena',
        'last_name': 'Prakash',
        'phone': '09769228347',
        'role': User.Role.ADMIN,
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

# ─── Projects (Categories) ───────────────────────────────────────────────────
projects_data = [
    {'title': 'Education & Skill Development', 'description': 'Theatre programs, computer literacy, employability training in schools and colleges.'},
    {'title': 'Health Care', 'description': 'Health camps, cataract operations, HIV/AIDS prevention, and community health awareness.'},
    {'title': 'Water and Sanitation (WASH)', 'description': 'Hygiene awareness, safe drinking water, and sanitation projects.'},
    {'title': 'Disaster Response', 'description': 'Emergency relief — food, medicine, and clothing for communities affected by natural disasters.'},
    {'title': 'Women Empowerment', 'description': 'Self Help Group formation, tailoring, embroidery, and artisan skills training.'},
    {'title': 'Special Support Programme', 'description': 'Support for specially-abled children, orphans, and elderly in old age homes.'},
]
project_objs = {}
for p in projects_data:
    obj, created = Project.objects.get_or_create(title=p['title'], defaults=p)
    project_objs[p['title']] = obj
    status = "created" if created else "exists"
    print(f"  ✓ Project {status}: {obj.title}")

# ─── Sample Activities (from scraped milestones data) ────────────────────────
activities_data = [
    {
        'title': 'Government School Transformation – Chinnagenehalli, Bangalore',
        'description': 'Partnered with Child Rights Foundation and Amazon volunteers to repaint dirty walls with beautiful artworks at Chinnagenehalli Government School, creating a better learning environment for underprivileged kids.',
        'event_date': '2023-05-27',
        'year': 2023,
        'location': 'Bangalore, Karnataka',
        'impact': 'Transformed a government school with 100+ volunteers, improving the learning environment.',
        'beneficiaries_count': 200,
        'project': project_objs['Education & Skill Development'],
    },
    {
        'title': 'Cancer Awareness Health Camp – Mumbai',
        'description': 'Organized cancer awareness health camps in Mumbai over 3 consecutive months (October, November, December 2022), supported by the Global Cancer Mission.',
        'event_date': '2022-12-01',
        'year': 2022,
        'location': 'Mumbai, Maharashtra',
        'impact': 'Reached 930 people over 3 months with cancer awareness and screening.',
        'beneficiaries_count': 930,
        'project': project_objs['Health Care'],
    },
    {
        'title': 'Livelihood Sewing Machine Distribution – West Bengal',
        'description': 'Distributed 25 sewing machines to women in rural West Bengal to enable self-employment through tailoring and embroidery work.',
        'event_date': '2021-09-01',
        'year': 2021,
        'location': 'West Bengal',
        'impact': '25 women given sewing machines to generate sustainable income.',
        'beneficiaries_count': 25,
        'project': project_objs['Women Empowerment'],
    },
    {
        'title': 'COVID-19 Ration Relief Distribution',
        'description': 'Distributed over 2,500 dry ration kits to migrant workers, tribal families, and differently-abled individuals across 9 states during the COVID-19 pandemic. Over 200 migrants were assisted in returning home.',
        'event_date': '2020-06-01',
        'year': 2020,
        'location': 'Pan India (9 states)',
        'impact': '2,500+ ration kits distributed. 200+ migrants helped to return home.',
        'beneficiaries_count': 2700,
        'project': project_objs['Disaster Response'],
    },
    {
        'title': 'Orissa Floods Emergency Relief',
        'description': 'Provided emergency relief — food, medicine, and essential supplies — to 300 families affected by the Orissa floods, in coordination with partner NGO Live to Give.',
        'event_date': '2021-10-01',
        'year': 2021,
        'location': 'Odisha',
        'impact': '300 flood-affected families received emergency supplies.',
        'beneficiaries_count': 300,
        'project': project_objs['Disaster Response'],
    },
    {
        'title': 'Free Cataract Operations – Hyderabad & Mumbai',
        'description': 'Supported and facilitated 413 free cataract operations for elderly and underprivileged patients in Hyderabad and Mumbai.',
        'event_date': '2022-01-01',
        'year': 2022,
        'location': 'Hyderabad & Mumbai',
        'impact': '413 patients received free cataract operations restoring their vision.',
        'beneficiaries_count': 413,
        'project': project_objs['Health Care'],
    },
]
for a in activities_data:
    obj, created = Activity.objects.get_or_create(
        title=a['title'],
        year=a['year'],
        defaults=a
    )
    status = "created" if created else "exists"
    print(f"  ✓ Activity {status}: {obj.title[:50]}...")

print("\n✅ Seeding complete! VKS Sharanya database is populated.")
print("   Admin Login: admin@vks-sharanyango.org.in / VKSAdmin@2024!")
