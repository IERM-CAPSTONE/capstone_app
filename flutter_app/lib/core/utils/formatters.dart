import 'package:intl/intl.dart';

class Formatters {
  // Date formatters
  static final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');
  static final DateFormat timeFormat = DateFormat('HH:mm');
  
  // Number formatters
  static final NumberFormat currencyFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
  );
  
  static final NumberFormat numberFormat = NumberFormat.decimalPattern('vi_VN');
  
  // Format date
  static String formatDate(DateTime date) {
    return dateFormat.format(date);
  }
  
  // Format date time
  static String formatDateTime(DateTime dateTime) {
    return dateTimeFormat.format(dateTime);
  }
  
  // Format time
  static String formatTime(DateTime dateTime) {
    return timeFormat.format(dateTime);
  }
  
  // Format currency
  static String formatCurrency(double amount) {
    return currencyFormat.format(amount);
  }
  
  // Format number
  static String formatNumber(double number) {
    return numberFormat.format(number);
  }
  
  // Format phone number
  static String formatPhoneNumber(String phone) {
    if (phone.length == 10) {
      return '${phone.substring(0, 4)} ${phone.substring(4, 7)} ${phone.substring(7)}';
    }
    return phone;
  }
}

