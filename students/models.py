from django.db import models
from django.conf import settings
from courses.models import Course


class Student(models.Model):
    """Unified student record managed by staff — covers enquiries and joined students."""

    class Status(models.TextChoices):
        ENQUIRED = 'ENQUIRED', 'Enquired'
        JOINED   = 'JOINED',   'Joined'
        DROPPED  = 'DROPPED',  'Dropped Out'

    class Gender(models.TextChoices):
        MALE   = 'MALE',   'Male'
        FEMALE = 'FEMALE', 'Female'
        OTHER  = 'OTHER',  'Other'

    class Centre(models.TextChoices):
        MUMBAI      = 'MUMBAI',      'Mumbai'
        HYDERABAD   = 'HYDERABAD',   'Hyderabad'
        ONLINE      = 'ONLINE',      'Online'
        NOT_DECIDED = 'NOT_DECIDED', 'Not Decided'

    class ReferredBy(models.TextChoices):
        REFERRAL     = 'REFERRAL',     'Referral'
        WALK_IN      = 'WALK_IN',      'Walk-in'
        SOCIAL_MEDIA = 'SOCIAL_MEDIA', 'Social Media'
        OTHER        = 'OTHER',        'Other'

    # Basic Info
    name          = models.CharField(max_length=150)
    phone         = models.CharField(max_length=15)
    email         = models.EmailField(blank=True)
    date_of_birth = models.DateField(null=True, blank=True)
    gender        = models.CharField(max_length=10, choices=Gender.choices, blank=True)
    address       = models.TextField(blank=True)
    education     = models.CharField(max_length=200, blank=True)

    # Academy Info
    status       = models.CharField(max_length=15, choices=Status.choices, default=Status.ENQUIRED)
    centre       = models.CharField(max_length=20, choices=Centre.choices, default=Centre.NOT_DECIDED)
    course       = models.ForeignKey(Course, on_delete=models.SET_NULL, null=True, blank=True, related_name='students')
    referred_by  = models.CharField(max_length=20, choices=ReferredBy.choices, default=ReferredBy.WALK_IN)
    enquiry_date = models.DateField(null=True, blank=True)
    joined_date  = models.DateField(null=True, blank=True)

    # Fee Info
    total_fee = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    remarks   = models.TextField(blank=True)

    # Birthday wish tracking
    last_birthday_wish_year = models.IntegerField(null=True, blank=True)

    # Managed by
    added_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='added_students'
    )

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Student'
        verbose_name_plural = 'Students'

    def __str__(self):
        return f"{self.name} — {self.centre} — {self.status}"

    @property
    def fee_paid(self):
        return sum(p.amount for p in self.fee_payments.all())

    @property
    def fee_remaining(self):
        return self.total_fee - self.fee_paid


class FeePayment(models.Model):
    """Individual fee payment record for a student."""

    class PaymentMode(models.TextChoices):
        CASH          = 'CASH',          'Cash'
        UPI           = 'UPI',           'UPI'
        BANK_TRANSFER = 'BANK_TRANSFER', 'Bank Transfer'
        CHEQUE        = 'CHEQUE',        'Cheque'
        OTHER         = 'OTHER',         'Other'

    student      = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='fee_payments')
    amount       = models.DecimalField(max_digits=10, decimal_places=2)
    payment_date = models.DateField()
    payment_mode = models.CharField(max_length=20, choices=PaymentMode.choices, default=PaymentMode.CASH)
    receipt_note = models.CharField(max_length=300, blank=True)
    recorded_by  = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='recorded_payments'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-payment_date']
        verbose_name = 'Fee Payment'
        verbose_name_plural = 'Fee Payments'

    def __str__(self):
        return f"Rs.{self.amount} — {self.student.name} on {self.payment_date}"


class Reminder(models.Model):
    """Fee or follow-up reminder set by staff for a student."""

    class ReminderType(models.TextChoices):
        FEE_REMINDER = 'FEE_REMINDER', 'Fee Reminder'
        FOLLOW_UP    = 'FOLLOW_UP',    'Follow-up Enquiry'
        CUSTOM       = 'CUSTOM',       'Custom Reminder'

    class RepeatInterval(models.TextChoices):
        NONE    = 'NONE',    'No Repeat'
        WEEKLY  = 'WEEKLY',  'Every Week'
        MONTHLY = 'MONTHLY', 'Every Month'

    student         = models.ForeignKey(Student, on_delete=models.CASCADE, related_name='reminders')
    reminder_type   = models.CharField(max_length=20, choices=ReminderType.choices, default=ReminderType.CUSTOM)
    message         = models.TextField()
    remind_at       = models.DateTimeField()
    repeat_interval = models.CharField(max_length=10, choices=RepeatInterval.choices, default=RepeatInterval.NONE)
    is_sent         = models.BooleanField(default=False)
    created_by      = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='created_reminders'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['remind_at']
        verbose_name = 'Reminder'
        verbose_name_plural = 'Reminders'

    def __str__(self):
        return f"[{self.reminder_type}] {self.student.name} — {self.remind_at.strftime('%d %b %Y')}"


class Broadcast(models.Model):
    """Event / announcement broadcast to joined students via SMS."""

    class AudienceType(models.TextChoices):
        ALL_JOINED = 'ALL_JOINED', 'All Joined Students'
        MUMBAI     = 'MUMBAI',     'Mumbai Students'
        HYDERABAD  = 'HYDERABAD',  'Hyderabad Students'
        ONLINE     = 'ONLINE',     'Online Students'

    title        = models.CharField(max_length=200)
    message      = models.TextField()
    audience     = models.CharField(max_length=20, choices=AudienceType.choices, default=AudienceType.ALL_JOINED)
    sent_count   = models.IntegerField(default=0)
    failed_count = models.IntegerField(default=0)
    sent_by      = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='broadcasts'
    )
    sent_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-sent_at']
        verbose_name = 'Broadcast'
        verbose_name_plural = 'Broadcasts'

    def __str__(self):
        return f"[{self.audience}] {self.title}"
