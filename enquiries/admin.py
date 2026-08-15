from django.contrib import admin
from .models import Enquiry


@admin.register(Enquiry)
class EnquiryAdmin(admin.ModelAdmin):
    list_display  = ('name', 'phone', 'email', 'location', 'fees_type', 'referred_by', 'status', 'enquiry_date', 'created_at')
    list_filter   = ('status', 'fees_type', 'referred_by', 'interested_course')
    search_fields = ('name', 'phone', 'email', 'location')
    ordering      = ('-created_at',)
    readonly_fields = ('created_at',)

    fieldsets = (
        ('Student Info', {
            'fields': ('name', 'phone', 'email', 'education', 'location')
        }),
        ('Course Interest', {
            'fields': ('interested_course', 'fees_type')
        }),
        ('Source', {
            'fields': ('referred_by', 'enquiry_date')
        }),
        ('Status & Remarks', {
            'fields': ('status', 'staff_remarks', 'created_at')
        }),
    )
