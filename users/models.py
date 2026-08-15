from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    """
    Custom user model extending Django's built-in AbstractUser.
    Adds a 'role' field to differentiate admin, staff, students and public users.
    """

    class Role(models.TextChoices):
        ADMIN = 'ADMIN', 'Admin'
        STAFF = 'STAFF', 'Staff'
        STUDENT = 'STUDENT', 'Student'
        PUBLIC = 'PUBLIC', 'Public'

    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=15, blank=True, null=True)
    role = models.CharField(
        max_length=10,
        choices=Role.choices,
        default=Role.PUBLIC,
    )

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = ['username', 'first_name', 'last_name']

    class Meta:
        verbose_name = 'User'
        verbose_name_plural = 'Users'
        ordering = ['-date_joined']

    def __str__(self):
        return f"{self.get_full_name()} ({self.email}) — {self.role}"

    @property
    def is_admin_user(self):
        return self.role == self.Role.ADMIN

    @property
    def is_staff_user(self):
        return self.role in [self.Role.ADMIN, self.Role.STAFF]
