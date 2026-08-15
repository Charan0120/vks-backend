from django.urls import path
from .views import (
    AdmissionCreateView, MyAdmissionsView,
    AdmissionListView, AdmissionDetailView, DocumentUploadView
)

urlpatterns = [
    path('', AdmissionCreateView.as_view(), name='admission-create'),
    path('my/', MyAdmissionsView.as_view(), name='my-admissions'),
    path('all/', AdmissionListView.as_view(), name='admission-list-admin'),
    path('<int:pk>/', AdmissionDetailView.as_view(), name='admission-detail'),
    path('<int:admission_id>/documents/', DocumentUploadView.as_view(), name='document-upload'),
]
