from django.urls import path
from .views import ActivityListCreateView, ActivityDetailView, ProjectListView

urlpatterns = [
    path('', ActivityListCreateView.as_view(), name='activity-list'),
    path('<int:pk>/', ActivityDetailView.as_view(), name='activity-detail'),
    path('projects/', ProjectListView.as_view(), name='project-list'),
]
