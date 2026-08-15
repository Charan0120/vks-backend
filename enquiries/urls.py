from django.urls import path
from .views import EnquirySubmitView, EnquiryListView, EnquiryDetailView

urlpatterns = [
    path('', EnquiryListView.as_view(), name='enquiry-list'),
    path('submit/', EnquirySubmitView.as_view(), name='enquiry-create'),
    path('<int:pk>/', EnquiryDetailView.as_view(), name='enquiry-detail'),
]
