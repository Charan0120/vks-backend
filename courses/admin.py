from django.contrib import admin
from .models import Course, CentreContact


@admin.register(Course)
class CourseAdmin(admin.ModelAdmin):
    list_display = ('code', 'title', 'duration_months', 'is_active', 'created_at')
    list_filter = ('is_active',)
    search_fields = ('code', 'title')
    list_editable = ('is_active',)


@admin.register(CentreContact)
class CentreContactAdmin(admin.ModelAdmin):
    list_display = ('centre', 'phone_number', 'email')
    list_filter = ('centre',)
    search_fields = ('centre', 'phone_number', 'email')
