import requests
from datetime import timedelta
from django.utils import timezone
from django.conf import settings
from rest_framework import generics, status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Student, FeePayment, Reminder, Broadcast
from .serializers import (
    StudentListSerializer, StudentDetailSerializer,
    FeePaymentSerializer, ReminderSerializer, BroadcastSerializer,
)


class IsStaffOrAdmin(permissions.BasePermission):
    def has_permission(self, request, view):
        return request.user.is_authenticated and request.user.role in ['ADMIN', 'STAFF']


def send_sms(phone, message):
    """Send SMS via Fast2SMS API."""
    api_key = getattr(settings, 'FAST2SMS_API_KEY', '')
    if not api_key:
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
        data = resp.json()
        return data.get('return', False)
    except Exception:
        return False


# ─── Students ────────────────────────────────────────────────────────────────

class StudentListCreateView(generics.ListCreateAPIView):
    permission_classes = [IsStaffOrAdmin]

    def get_serializer_class(self):
        return StudentListSerializer

    def get_queryset(self):
        qs = Student.objects.select_related('course', 'added_by').prefetch_related('fee_payments')
        user = self.request.user

        # Staff can only see students of their own centre
        if user.role == 'STAFF' and hasattr(user, 'centre') and user.centre != 'ALL':
            qs = qs.filter(centre=user.centre)

        # Filters
        status_f = self.request.query_params.get('status')
        centre_f = self.request.query_params.get('centre')
        search   = self.request.query_params.get('search')

        if status_f:
            qs = qs.filter(status=status_f)
        if centre_f:
            qs = qs.filter(centre=centre_f)
        if search:
            qs = qs.filter(name__icontains=search) | qs.filter(phone__icontains=search)

        return qs

    def perform_create(self, serializer):
        serializer.save(added_by=self.request.user)


class StudentDetailView(generics.RetrieveUpdateDestroyAPIView):
    permission_classes = [IsStaffOrAdmin]
    serializer_class   = StudentDetailSerializer
    queryset           = Student.objects.select_related('course', 'added_by').prefetch_related('fee_payments', 'reminders')


# ─── Fee Payments ─────────────────────────────────────────────────────────────

class FeePaymentCreateView(APIView):
    permission_classes = [IsStaffOrAdmin]

    def post(self, request, student_id):
        try:
            student = Student.objects.get(pk=student_id)
        except Student.DoesNotExist:
            return Response({'error': 'Student not found.'}, status=404)

        serializer = FeePaymentSerializer(data=request.data)
        if serializer.is_valid():
            payment = serializer.save(student=student, recorded_by=request.user)

            # Send SMS to student about the payment
            fee_remaining = student.fee_remaining
            msg = (
                f"Dear {student.name}, we have received your fee payment of "
                f"Rs.{payment.amount} on {payment.payment_date}. "
                f"Remaining balance: Rs.{fee_remaining}. "
                f"— VKS Academy"
            )
            send_sms(student.phone, msg)

            return Response(FeePaymentSerializer(payment).data, status=201)
        return Response(serializer.errors, status=400)


class FeePaymentListView(generics.ListAPIView):
    permission_classes = [IsStaffOrAdmin]
    serializer_class   = FeePaymentSerializer

    def get_queryset(self):
        return FeePayment.objects.filter(student_id=self.kwargs['student_id'])


# ─── Reminders ───────────────────────────────────────────────────────────────

class ReminderCreateView(APIView):
    permission_classes = [IsStaffOrAdmin]

    def post(self, request, student_id):
        try:
            student = Student.objects.get(pk=student_id)
        except Student.DoesNotExist:
            return Response({'error': 'Student not found.'}, status=404)

        serializer = ReminderSerializer(data=request.data)
        if serializer.is_valid():
            reminder = serializer.save(student=student, created_by=request.user)
            return Response(ReminderSerializer(reminder).data, status=201)
        return Response(serializer.errors, status=400)


class ReminderListView(generics.ListAPIView):
    """All upcoming (unsent) reminders — used in the app's Reminders screen."""
    permission_classes = [IsStaffOrAdmin]
    serializer_class   = ReminderSerializer

    def get_queryset(self):
        user = self.request.user
        qs   = Reminder.objects.filter(is_sent=False).select_related('student')
        if user.role == 'STAFF' and hasattr(user, 'centre') and user.centre != 'ALL':
            qs = qs.filter(student__centre=user.centre)
        return qs


class ReminderDeleteView(generics.DestroyAPIView):
    permission_classes = [IsStaffOrAdmin]
    serializer_class   = ReminderSerializer
    queryset           = Reminder.objects.all()


# ─── Broadcast ───────────────────────────────────────────────────────────────

class BroadcastSendView(APIView):
    permission_classes = [IsStaffOrAdmin]

    def post(self, request):
        serializer = BroadcastSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=400)

        audience = serializer.validated_data['audience']
        message  = serializer.validated_data['message']
        title    = serializer.validated_data['title']

        # Get target students
        students_qs = Student.objects.filter(status='JOINED')
        if audience != 'ALL_JOINED':
            students_qs = students_qs.filter(centre=audience)

        sent_count   = 0
        failed_count = 0
        for student in students_qs:
            if student.phone:
                ok = send_sms(student.phone, f"{title}\n\n{message}\n— VKS Academy")
                if ok:
                    sent_count += 1
                else:
                    failed_count += 1

        broadcast = Broadcast.objects.create(
            title        = title,
            message      = message,
            audience     = audience,
            sent_count   = sent_count,
            failed_count = failed_count,
            sent_by      = request.user,
        )
        return Response(BroadcastSerializer(broadcast).data, status=201)


class BroadcastListView(generics.ListAPIView):
    permission_classes = [IsStaffOrAdmin]
    serializer_class   = BroadcastSerializer
    queryset           = Broadcast.objects.all()


# ─── Dashboard Stats ─────────────────────────────────────────────────────────

class DashboardStatsView(APIView):
    permission_classes = [IsStaffOrAdmin]

    def get(self, request):
        user = request.user
        qs   = Student.objects.prefetch_related('fee_payments')

        if user.role == 'STAFF' and hasattr(user, 'centre') and user.centre != 'ALL':
            qs = qs.filter(centre=user.centre)

        joined   = qs.filter(status='JOINED')
        enquired = qs.filter(status='ENQUIRED')

        from django.utils.timezone import now
        today = now().date()
        birthdays_today = joined.filter(
            date_of_birth__month=today.month,
            date_of_birth__day=today.day,
        )

        pending_reminders = Reminder.objects.filter(
            is_sent=False, remind_at__date__lte=today
        )
        if user.role == 'STAFF' and hasattr(user, 'centre') and user.centre != 'ALL':
            pending_reminders = pending_reminders.filter(student__centre=user.centre)

        total_fees_collected = sum(
            p.amount for s in joined for p in s.fee_payments.all()
        )

        return Response({
            'total_students':       qs.count(),
            'joined':               joined.count(),
            'enquired':             enquired.count(),
            'birthdays_today':      birthdays_today.count(),
            'pending_reminders':    pending_reminders.count(),
            'total_fees_collected': float(total_fees_collected),
            'by_centre': {
                'mumbai':    qs.filter(centre='MUMBAI').count(),
                'hyderabad': qs.filter(centre='HYDERABAD').count(),
                'online':    qs.filter(centre='ONLINE').count(),
            },
            'birthdays_today_list': [
                {'id': s.id, 'name': s.name, 'phone': s.phone}
                for s in birthdays_today
            ],
        })


# ─── Excel / CSV Report Export ───────────────────────────────────────────────

class StudentExportCSVView(APIView):
    permission_classes = [IsStaffOrAdmin]

    def get(self, request):
        import csv
        from django.http import HttpResponse

        user = request.user
        qs   = Student.objects.select_related('course', 'added_by').prefetch_related('fee_payments')

        if user.role == 'STAFF' and hasattr(user, 'centre') and user.centre != 'ALL':
            qs = qs.filter(centre=user.centre)

        status_f = request.query_params.get('status')
        centre_f = request.query_params.get('centre')
        search   = request.query_params.get('search')

        if status_f and status_f != 'ALL':
            qs = qs.filter(status=status_f)
        if centre_f and centre_f != 'ALL':
            qs = qs.filter(centre=centre_f)
        if search:
            qs = qs.filter(name__icontains=search) | qs.filter(phone__icontains=search)

        filename_suffix = status_f.lower() if status_f and status_f != 'ALL' else 'all'
        response = HttpResponse(content_type='text/csv; charset=utf-8')
        response['Content-Disposition'] = f'attachment; filename="vks_students_report_{filename_suffix}.csv"'

        # Write UTF-8 BOM for Microsoft Excel compatibility
        response.write('\ufeff')

        writer = csv.writer(response)
        writer.writerow([
            'Student ID',
            'Full Name',
            'Phone Number',
            'Email Address',
            'Status',
            'Centre',
            'Course',
            'Total Agreed Fee (INR)',
            'Amount Paid (INR)',
            'Remaining Due (INR)',
            'Date of Birth',
            'Gender',
            'Education',
            'Residential Address',
            'Enquiry Date',
            'Joined Date',
            'Staff Remarks / Notes',
            'Registered By',
            'Created Date',
        ])

        for s in qs:
            writer.writerow([
                s.id,
                s.name,
                s.phone,
                s.email or '',
                s.status,
                s.centre,
                s.course.title if s.course else 'N/A',
                float(s.total_fee),
                float(s.fee_paid),
                float(s.fee_remaining),
                s.date_of_birth.strftime('%Y-%m-%d') if s.date_of_birth else '',
                s.gender or '',
                s.education or '',
                s.address or '',
                s.enquiry_date.strftime('%Y-%m-%d') if s.enquiry_date else '',
                s.joined_date.strftime('%Y-%m-%d') if s.joined_date else '',
                s.remarks or '',
                (s.added_by.get_full_name() or s.added_by.username) if s.added_by else '',
                s.created_at.strftime('%Y-%m-%d %H:%M'),
            ])

        return response
