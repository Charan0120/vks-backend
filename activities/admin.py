from django.contrib import admin
from .models import Project, Activity


@admin.register(Project)
class ProjectAdmin(admin.ModelAdmin):
    list_display = ('title', 'created_at')
    search_fields = ('title',)


@admin.register(Activity)
class ActivityAdmin(admin.ModelAdmin):
    list_display = ('title', 'year', 'location', 'beneficiaries_count', 'project', 'created_at')
    list_filter = ('year', 'project')
    search_fields = ('title', 'location', 'impact')
    ordering = ('-year', '-event_date')
    fieldsets = (
        ('Activity Details', {
            'fields': ('title', 'description', 'project', 'event_date', 'year')
        }),
        ('Location & Impact', {
            'fields': ('location', 'impact', 'beneficiaries_count')
        }),
    )
