
from django.contrib import admin
from django.urls import path
from api.views import (
    PriceListView,
    RegisterView,
    LoginView,
    WatchlistView
)

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/prices/', PriceListView.as_view(), name='price-list'),
    path('api/register/', RegisterView.as_view(), name='register'),
    path('api/login/', LoginView.as_view(), name='login'),
    path('api/watchlist/', WatchlistView.as_view(), name='watchlist'),
]