"""
Management command: send_scheduled_sms
Run this daily via a cron job to:
  1. Send birthday wishes to joined students
  2. Send due reminders (fee/follow-up) via SMS
  3. Reschedule repeating reminders
"""
from datetime import timedelta
from django.core.management.base import BaseCommand
from django.utils.timezone import now
from django.conf import settings
import requests


def send_sms(phone, message):
    api_key = getattr(settings, 'FAST2SMS_API_KEY', '')
    if not api_key:
        print(f"  [SKIP] No FAST2SMS_API_KEY — would send to {phone}: {message[:40]}...")
        return False
    try:
        resp = requests.post(
            'https://www.fast2sms.com/dev/bulkV2',
            headers={'authorization': api_key},
            json={
                'route': 'q',
                'message': message,
                'language': 'english',
                'flash': 0,
                'numbers': phone,
            },
            timeout=10,
        )
        return resp.json().get('return', False)
    except Exception as e:
        print(f"  [ERROR] SMS failed for {phone}: {e}")
        return False


class Command(BaseCommand):
    help = 'Send birthday wishes and due reminder SMS messages to students.'

    def handle(self, *args, **options):
        from students.models import Student, Reminder

        today = now().date()
        self.stdout.write(f"\n=== VKS Scheduled SMS — {today} ===\n")

        # ── 1. Birthday Wishes ───────────────────────────────────────────────
        self.stdout.write("Checking birthdays...")
        birthday_students = Student.objects.filter(
            status='JOINED',
            date_of_birth__month=today.month,
            date_of_birth__day=today.day,
        ).exclude(last_birthday_wish_year=today.year)

        for student in birthday_students:
            if not student.phone:
                continue
            msg = (
                f"Happy Birthday {student.name}! "
                f"Wishing you a wonderful day filled with joy. "
                f"Best wishes from all of us at VKS Academy! 🎂🎉"
            )
            ok = send_sms(student.phone, msg)
            if ok:
                student.last_birthday_wish_year = today.year
                student.save(update_fields=['last_birthday_wish_year'])
                self.stdout.write(self.style.SUCCESS(f"  ✓ Birthday wish sent to {student.name} ({student.phone})"))
            else:
                self.stdout.write(self.style.WARNING(f"  ✗ Failed for {student.name} ({student.phone})"))

        # ── 2. Due Reminders ─────────────────────────────────────────────────
        self.stdout.write("\nChecking due reminders...")
        due_reminders = Reminder.objects.filter(
            is_sent=False,
            remind_at__date__lte=today,
        ).select_related('student')

        for reminder in due_reminders:
            student = reminder.student
            if not student.phone:
                reminder.is_sent = True
                reminder.save(update_fields=['is_sent'])
                continue

            ok = send_sms(student.phone, reminder.message)
            if ok:
                self.stdout.write(self.style.SUCCESS(
                    f"  ✓ Reminder sent to {student.name} ({student.phone}) — {reminder.reminder_type}"
                ))
            else:
                self.stdout.write(self.style.WARNING(
                    f"  ✗ Failed for {student.name} ({student.phone})"
                ))

            # Mark as sent
            reminder.is_sent = True
            reminder.save(update_fields=['is_sent'])

            # Reschedule if repeating
            if reminder.repeat_interval == 'WEEKLY':
                Reminder.objects.create(
                    student         = student,
                    reminder_type   = reminder.reminder_type,
                    message         = reminder.message,
                    remind_at       = reminder.remind_at + timedelta(weeks=1),
                    repeat_interval = reminder.repeat_interval,
                    created_by      = reminder.created_by,
                )
                self.stdout.write(f"    ↻ Rescheduled weekly reminder for {student.name}")
            elif reminder.repeat_interval == 'MONTHLY':
                next_month = reminder.remind_at.replace(day=1) + timedelta(days=32)
                next_remind = next_month.replace(day=reminder.remind_at.day)
                Reminder.objects.create(
                    student         = student,
                    reminder_type   = reminder.reminder_type,
                    message         = reminder.message,
                    remind_at       = next_remind,
                    repeat_interval = reminder.repeat_interval,
                    created_by      = reminder.created_by,
                )
                self.stdout.write(f"    ↻ Rescheduled monthly reminder for {student.name}")

        self.stdout.write(self.style.SUCCESS("\n=== Done ===\n"))
