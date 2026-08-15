from django.db import models


class Project(models.Model):
    """Top-level grouping for activities (e.g., Healthcare, Women Empowerment)."""
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['title']
        verbose_name = 'Project'
        verbose_name_plural = 'Projects'

    def __str__(self):
        return self.title


class Activity(models.Model):
    """
    An individual NGO activity or event.
    Can belong to a Project (category) or stand alone.
    """
    title = models.CharField(max_length=255)
    description = models.TextField()
    event_date = models.DateField(null=True, blank=True)
    year = models.PositiveIntegerField()
    location = models.CharField(max_length=255, blank=True)
    impact = models.TextField(blank=True, help_text='Describe the impact of this activity.')
    beneficiaries_count = models.PositiveIntegerField(default=0)
    project = models.ForeignKey(
        Project,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='activities',
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-year', '-event_date']
        verbose_name = 'Activity'
        verbose_name_plural = 'Activities'

    def __str__(self):
        return f"{self.title} ({self.year})"
