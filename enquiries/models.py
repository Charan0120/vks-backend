from django.db import models
from courses.models import Course


class Enquiry(models.Model):
    """Enquiry submitted by a student or walk-in visitor."""

    class Status(models.TextChoices):
        NEW       = 'NEW',       'New'
        FOLLOW_UP = 'FOLLOW_UP', 'Follow Up Required'
        ENROLLED  = 'ENROLLED',  'Enrolled'
        REJECTED  = 'REJECTED',  'Rejected'

    class FeesType(models.TextChoices):
        CRASH_COURSE = 'CRASH_COURSE', 'Crash Course'
        DIPLOMA      = 'DIPLOMA',      'Diploma'
        BSC          = 'BSC',          'B.Sc'
        OTHER        = 'OTHER',        'Other'

    class ReferredBy(models.TextChoices):
        REFERRAL     = 'REFERRAL',     'Referral'
        JD           = 'JD',           'JD'
        WALK_IN      = 'WALK_IN',      'Walk-in'
        SOCIAL_MEDIA = 'SOCIAL_MEDIA', 'Social Media'
        LINKEDIN     = 'LINKEDIN',     'LinkedIn'
        OTHER        = 'OTHER',        'Other'

    class Centre(models.TextChoices):
        MUMBAI     = 'MUMBAI',     'Mumbai'
        HYDERABAD  = 'HYDERABAD',  'Hyderabad'
        ONLINE     = 'ONLINE',     'Online'
        NOT_DECIDED = 'NOT_DECIDED', 'Not Decided'

    # Basic Info
    name      = models.CharField(max_length=150)
    phone     = models.CharField(max_length=15)
    email     = models.EmailField(blank=True)
    education = models.CharField(max_length=200, blank=True, help_text='Highest qualification')
    location  = models.CharField(max_length=200, blank=True, help_text='Where the student lives')

    # Preferred Centre to Enroll
    preferred_centre = models.CharField(
        max_length=20, choices=Centre.choices, default=Centre.NOT_DECIDED,
        help_text='Which VKS centre does the student want to join?'
    )

    # Course Interest
    interested_course = models.ForeignKey(
        Course, on_delete=models.SET_NULL, null=True, blank=True, related_name='enquiries',
    )
    fees_type = models.CharField(max_length=20, choices=FeesType.choices, blank=True)

    # Source
    referred_by = models.CharField(max_length=20, choices=ReferredBy.choices, default=ReferredBy.WALK_IN)

    # Status & Admin fields
    status        = models.CharField(max_length=15, choices=Status.choices, default=Status.NEW)
    staff_remarks = models.TextField(blank=True)

    # Dates
    enquiry_date = models.DateField(null=True, blank=True, help_text='Date of walk-in or enquiry')
    created_at   = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Enquiry'
        verbose_name_plural = 'Enquiries'

    def __str__(self):
        return f"{self.name} — {self.preferred_centre} — {self.status} ({self.created_at.strftime('%d %b %Y')})"
