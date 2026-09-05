from django.contrib import admin
from django import forms
from .models import User


class UserAdminForm(forms.ModelForm):
    username = forms.CharField(required=False, help_text="Auto-generated from email if left blank.")
    first_name = forms.CharField(required=False)
    last_name = forms.CharField(required=False)
    phone = forms.CharField(required=False)
    password = forms.CharField(
        widget=forms.PasswordInput(),
        required=False,
        help_text="Leave blank to keep existing password, or enter a new password."
    )

    class Meta:
        model = User
        fields = ['email', 'username', 'first_name', 'last_name', 'phone', 'role', 'centre', 'is_active', 'is_staff', 'is_superuser']

    def clean(self):
        cleaned_data = super().clean()
        username = cleaned_data.get('username')
        email = cleaned_data.get('email')
        if not username and email:
            cleaned_data['username'] = email.split('@')[0]
        return cleaned_data

    def save(self, commit=True):
        user = super().save(commit=False)
        password = self.cleaned_data.get('password')
        if not user.username and user.email:
            user.username = user.email.split('@')[0]
        if password:
            user.set_password(password)
        if commit:
            user.save()
        return user



@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    form = UserAdminForm
    list_display = ('email', 'first_name', 'last_name', 'role', 'centre', 'is_staff', 'is_active', 'date_joined')
    list_filter = ('role', 'centre', 'is_staff', 'is_active')
    search_fields = ('email', 'first_name', 'last_name', 'phone')
    ordering = ('-date_joined',)
    readonly_fields = ('date_joined', 'last_login')

    fieldsets = (
        ('Account Credentials', {
            'fields': ('email', 'username', 'password')
        }),
        ('Personal Information', {
            'fields': ('first_name', 'last_name', 'phone')
        }),
        ('Role & Centre Assignment', {
            'fields': ('role', 'centre')
        }),
        ('Permissions & Status', {
            'fields': ('is_active', 'is_staff', 'is_superuser')
        }),
        ('Important Dates', {
            'fields': ('date_joined', 'last_login')
        }),
    )


