from django.db import models


class Course(models.Model):
    """Catalog of courses offered by the institute."""
    code = models.CharField(max_length=20, unique=True)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    duration_months = models.PositiveIntegerField(default=1)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['title']
        verbose_name = 'Course'
        verbose_name_plural = 'Courses'

    def __str__(self):
        return f"{self.code} — {self.title}"


class CentreContact(models.Model):
    """Dynamic contact numbers set by admin/staff based on centre/location."""
    class Centre(models.TextChoices):
        MUMBAI = 'MUMBAI', 'Mumbai'
        HYDERABAD = 'HYDERABAD', 'Hyderabad'
        ONLINE = 'ONLINE', 'Online'

    centre = models.CharField(
        max_length=20,
        choices=Centre.choices,
        unique=True,
    )
    phone_number = models.CharField(max_length=20)
    email = models.EmailField(blank=True)
    address = models.TextField(blank=True)

    class Meta:
        verbose_name = 'Centre Contact Details'
        verbose_name_plural = 'Centre Contact Details'

    def __str__(self):
        return f"{self.get_centre_display()} — {self.phone_number}"
