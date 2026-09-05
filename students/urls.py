from django.urls import path
from . import views

urlpatterns = [
    # Dashboard
    path('dashboard/', views.DashboardStatsView.as_view(), name='dashboard-stats'),

    # Students
    path('', views.StudentListCreateView.as_view(), name='student-list-create'),
    path('<int:pk>/', views.StudentDetailView.as_view(), name='student-detail'),

    # Fee Payments
    path('<int:student_id>/fees/', views.FeePaymentListView.as_view(), name='fee-list'),
    path('<int:student_id>/fees/add/', views.FeePaymentCreateView.as_view(), name='fee-add'),

    # Reminders
    path('<int:student_id>/reminders/add/', views.ReminderCreateView.as_view(), name='reminder-add'),
    path('reminders/', views.ReminderListView.as_view(), name='reminder-list'),
    path('reminders/<int:pk>/delete/', views.ReminderDeleteView.as_view(), name='reminder-delete'),

    # Broadcast
    path('broadcast/', views.BroadcastSendView.as_view(), name='broadcast-send'),
    path('broadcast/history/', views.BroadcastListView.as_view(), name='broadcast-history'),

    # Export Report (Excel / CSV)
    path('export-excel/', views.StudentExportExcelView.as_view(), name='student-export-excel'),
    path('export-csv/', views.StudentExportExcelView.as_view(), name='student-export-csv'),
]
