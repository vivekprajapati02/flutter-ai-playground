import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ToolExecutionResult {
  final Map<String, dynamic> data;
  final String? qrData;
  final Map<String, dynamic>? githubProfile;
  final String? pickedImagePath;

  ToolExecutionResult(
    this.data, {
    this.qrData,
    this.githubProfile,
    this.pickedImagePath,
  });
}

class ToolService {
  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio(BaseOptions(connectTimeout: const Duration(seconds: 15)));

  Future<ToolExecutionResult> executeTool(
    String name,
    Map<String, dynamic> arguments,
  ) async {
    switch (name) {
      case 'open_camera':
        return _pickImage(ImageSource.camera);
      case 'open_gallery':
        return _pickImage(ImageSource.gallery);
      case 'calculate_bmi':
        return _calculateBmi(arguments);
      case 'generate_qr_code':
        return _generateQrCode(arguments);
      case 'convert_currency':
        return _convertCurrency(arguments);
      case 'fetch_github_profile':
        return _fetchGithubProfile(arguments);
      default:
        return ToolExecutionResult({'error': 'Unknown tool: $name'});
    }
  }

  Future<ToolExecutionResult> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 90,
      );
      if (file == null) {
        return ToolExecutionResult({
          'result': 'User cancelled image selection.',
        });
      }
      return ToolExecutionResult(
        {'result': 'Image captured successfully.', 'path': file.path},
        pickedImagePath: file.path,
      );
    } on PlatformException catch (e) {
      final msg = e.code == 'camera_access_denied'
          ? 'Camera permission was denied.'
          : 'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}: ${e.message}';
      return ToolExecutionResult({'error': msg});
    }
  }

  ToolExecutionResult _calculateBmi(Map<String, dynamic> args) {
    final weight = (args['weight_kg'] as num?)?.toDouble();
    final heightCm = (args['height_cm'] as num?)?.toDouble();
    if (weight == null || heightCm == null || heightCm <= 0) {
      return ToolExecutionResult({
        'error': 'weight_kg and height_cm are required and must be positive.',
      });
    }
    final heightM = heightCm / 100;
    final bmi = weight / (heightM * heightM);
    String category;
    if (bmi < 18.5) {
      category = 'Underweight';
    } else if (bmi < 25) {
      category = 'Normal weight';
    } else if (bmi < 30) {
      category = 'Overweight';
    } else {
      category = 'Obese';
    }
    return ToolExecutionResult({
      'bmi': double.parse(bmi.toStringAsFixed(1)),
      'category': category,
    });
  }

  ToolExecutionResult _generateQrCode(Map<String, dynamic> args) {
    final data = args['data'] as String?;
    if (data == null || data.trim().isEmpty) {
      return ToolExecutionResult({'error': 'data is required.'});
    }
    return ToolExecutionResult(
      {'result': 'QR code generated.', 'data': data},
      qrData: data,
    );
  }

  // Frankfurter: free, no API key, ECB-sourced daily rates — zero setup
  // friction, ideal for a demo.
  Future<ToolExecutionResult> _convertCurrency(
    Map<String, dynamic> args,
  ) async {
    final amount = (args['amount'] as num?)?.toDouble();
    final from = (args['from'] as String?)?.toUpperCase();
    final to = (args['to'] as String?)?.toUpperCase();
    if (amount == null || from == null || to == null) {
      return ToolExecutionResult({
        'error': 'amount, from, and to are required.',
      });
    }
    try {
      final response = await _dio.get(
        'https://api.frankfurter.app/latest',
        queryParameters: {'amount': amount, 'from': from, 'to': to},
      );
      final rates = response.data['rates'] as Map<String, dynamic>?;
      final converted = rates?[to];
      if (converted == null) {
        return ToolExecutionResult({
          'error': 'Could not convert $from to $to.',
        });
      }
      return ToolExecutionResult({
        'amount': amount,
        'from': from,
        'to': to,
        'converted': converted,
      });
    } on DioException catch (e) {
      return ToolExecutionResult({
        'error': 'Currency conversion failed: ${e.message}',
      });
    }
  }

  // Public GitHub API, no auth needed for unauthenticated read access
  // (60 req/hr/IP limit, acceptable for a demo).
  Future<ToolExecutionResult> _fetchGithubProfile(
    Map<String, dynamic> args,
  ) async {
    final username = args['username'] as String?;
    if (username == null || username.trim().isEmpty) {
      return ToolExecutionResult({'error': 'username is required.'});
    }
    try {
      final response = await _dio.get('https://api.github.com/users/$username');
      final d = response.data as Map<String, dynamic>;
      final profile = {
        'login': d['login'],
        'name': d['name'],
        'bio': d['bio'],
        'followers': d['followers'],
        'public_repos': d['public_repos'],
        'avatar_url': d['avatar_url'],
        'html_url': d['html_url'],
      };
      return ToolExecutionResult(profile, githubProfile: profile);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return ToolExecutionResult({
          'error': 'GitHub user "$username" not found.',
        });
      }
      return ToolExecutionResult({'error': 'GitHub lookup failed: ${e.message}'});
    }
  }
}
