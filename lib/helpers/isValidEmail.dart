bool isValidEmail(String email) {
  final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  // ^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$ -> this regex does not allow for the use of special characters or domains longer than 4 characters
  return emailRegex.hasMatch(email);
}
