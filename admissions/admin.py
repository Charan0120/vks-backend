from django.contrib import admin
from .models import Admission, Document


class DocumentInline(admin.TabularInline):
    """Show uploaded documents inline inside the Admission detail view."""
    model = Document
    extra = 0
    readonly_fields = ('original_filename', 'document_type', 'file', 'uploaded_at')
    can_delete = False


@admin.register(Admission)
class AdmissionAdmin(admin.ModelAdmin):
    list_display = ('student_name', 'selected_course', 'preferred_centre', 'mobile_number', 'status', 'created_at')
    list_filter = ('status', 'selected_course', 'preferred_centre', 'gender')
    search_fields = ('student_name', 'mobile_number', 'email')
    ordering = ('-created_at',)
    readonly_fields = ('user', 'created_at', 'updated_at')
    inlines = [DocumentInline]

    fieldsets = (
        ('Student Information', {
            'fields': ('student_name', 'father_name', 'mother_name', 'gender', 'date_of_birth')
        }),
        ('Contact Details', {
            'fields': ('mobile_number', 'email', 'address')
        }),
        ('Academic & Course', {
            'fields': ('qualification', 'selected_course', 'preferred_centre')
        }),
        ('Application Status', {
            'fields': ('status', 'admin_remarks')
        }),
        ('System Info', {
            'fields': ('user', 'created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )


@admin.register(Document)
class DocumentAdmin(admin.ModelAdmin):
    list_display = ('admission', 'document_type', 'original_filename', 'uploaded_at')
    list_filter = ('document_type',)
    search_fields = ('admission__student_name',)
    readonly_fields = ('uploaded_at',)
