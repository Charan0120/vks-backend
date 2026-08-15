from django.db import models
from django.conf import settings
from courses.models import Course


class Admission(models.Model):
    """Student admission application submitted through the portal."""

    class Status(models.TextChoices):
        PENDING = 'PENDING', 'Pending Review'
        APPROVED = 'APPROVED', 'Approved'
        REJECTED = 'REJECTED', 'Rejected'
        ENROLLED = 'ENROLLED', 'Enrolled'

    class Gender(models.TextChoices):
        MALE = 'MALE', 'Male'
        FEMALE = 'FEMALE', 'Female'
        OTHER = 'OTHER', 'Other'

    # Linked account (required — registration first)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        related_name='admissions',
    )

    # Student Personal Details
    student_name = models.CharField(max_length=150)
    father_name = models.CharField(max_length=150)
    mother_name = models.CharField(max_length=150)
    gender = models.CharField(max_length=10, choices=Gender.choices)
    date_of_birth = models.DateField()
    mobile_number = models.CharField(max_length=15)
    email = models.EmailField()
    address = models.TextField()
    qualification = models.CharField(max_length=200)

    # Course
    selected_course = models.ForeignKey(
        Course,
        on_delete=models.SET_NULL,
        null=True,
        related_name='admissions',
    )

    # Admin fields
    status = models.CharField(max_length=10, choices=Status.choices, default=Status.PENDING)
    admin_remarks = models.TextField(blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-created_at']
        verbose_name = 'Admission Application'
        verbose_name_plural = 'Admission Applications'

    def __str__(self):
        return f"{self.student_name} — {self.selected_course} [{self.status}]"


class Document(models.Model):
    """File uploads attached to an admission application."""

    class DocumentType(models.TextChoices):
        AADHAAR = 'AADHAAR', 'Aadhaar Card'
        PHOTO = 'PHOTO', 'Passport Photo'
        TRANSFER_CERTIFICATE = 'TC', 'Transfer Certificate'
        MARKS_MEMO = 'MARKS_MEMO', 'Marks Memo'
        CERTIFICATE = 'CERTIFICATE', 'Other Certificate'

    admission = models.ForeignKey(
        Admission,
        on_delete=models.CASCADE,
        related_name='documents',
    )
    file = models.FileField(upload_to='admission_docs/%Y/%m/')
    document_type = models.CharField(max_length=20, choices=DocumentType.choices)
    original_filename = models.CharField(max_length=255)
    uploaded_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = 'Document'
        verbose_name_plural = 'Documents'

    def __str__(self):
        return f"{self.document_type} — {self.admission.student_name}"
