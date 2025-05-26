import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../utils/theme.dart';
import '../utils/responsive_builder.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isLogin = true;
  UserType _userType = UserType.client;

  // Form fields
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final List<String> _selectedCategories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _userType =
            _tabController.index == 0 ? UserType.client : UserType.professional;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (_isLogin) {
        await ref.read(authServiceProvider).signInWithEmail(
              _emailController.text,
              _passwordController.text,
            );
      } else {
        await ref.read(authServiceProvider).registerWithEmail(
              email: _emailController.text,
              password: _passwordController.text,
              name: _nameController.text,
              phone: _phoneController.text,
              userType: _userType,
              description: _userType == UserType.professional
                  ? _descriptionController.text
                  : null,
              categories:
                  _userType == UserType.professional ? _selectedCategories : null,
            );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Успешно влизане!'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    }
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Имейл',
        hintText: 'example@email.com',
        prefixIcon: Icon(Icons.email),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Моля, въведете имейл';
        }
        if (!value.contains('@')) {
          return 'Моля, въведете валиден имейл';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Парола',
        prefixIcon: Icon(Icons.lock),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Моля, въведете парола';
        }
        if (!_isLogin && value.length < 6) {
          return 'Паролата трябва да е поне 6 символа';
        }
        return null;
      },
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Име',
        prefixIcon: Icon(Icons.person),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Моля, въведете име';
        }
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      decoration: const InputDecoration(
        labelText: 'Телефон',
        prefixIcon: Icon(Icons.phone),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Моля, въведете телефон';
        }
        return null;
      },
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Описание',
        hintText: 'Разкажете за вашия опит и услуги...',
      ),
      validator: (value) {
        if (_userType == UserType.professional &&
            (value == null || value.isEmpty)) {
          return 'Моля, въведете описание';
        }
        return null;
      },
    );
  }

  Widget _buildCategorySelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Категории услуги'),
        const SizedBox(height: AppTheme.spacing_sm),
        Wrap(
          spacing: AppTheme.spacing_sm,
          runSpacing: AppTheme.spacing_sm,
          children: [
            _buildCategoryChip('ВиК'),
            _buildCategoryChip('Ел. услуги'),
            _buildCategoryChip('Ремонти'),
            _buildCategoryChip('Чистене'),
            _buildCategoryChip('Детегледачки'),
            _buildCategoryChip('Дом. любимци'),
          ],
        ),
        if (_userType == UserType.professional &&
            _selectedCategories.isEmpty &&
            !_isLogin)
          const Padding(
            padding: EdgeInsets.only(top: AppTheme.spacing_sm),
            child: Text(
              'Моля, изберете поне една категория',
              style: TextStyle(
                color: AppTheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategories.contains(category);
    return FilterChip(
      label: Text(category),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedCategories.add(category);
          } else {
            _selectedCategories.remove(category);
          }
        });
      },
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEmailField(),
          const SizedBox(height: AppTheme.spacing_md),
          _buildPasswordField(),
          if (!_isLogin) ...[
            const SizedBox(height: AppTheme.spacing_md),
            _buildNameField(),
            const SizedBox(height: AppTheme.spacing_md),
            _buildPhoneField(),
            if (_userType == UserType.professional) ...[
              const SizedBox(height: AppTheme.spacing_md),
              _buildDescriptionField(),
              const SizedBox(height: AppTheme.spacing_md),
              _buildCategorySelection(),
            ],
          ],
          const SizedBox(height: AppTheme.spacing_lg),
          ElevatedButton(
            onPressed: _submitForm,
            child: Text(_isLogin ? 'Вход' : 'Регистрация'),
          ),
          const SizedBox(height: AppTheme.spacing_md),
          TextButton(
            onPressed: () {
              setState(() {
                _isLogin = !_isLogin;
              });
            },
            child: Text(_isLogin
                ? 'Нямате акаунт? Регистрирайте се'
                : 'Имате акаунт? Влезте'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveBuilder(
        mobile: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacing_md),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: AppTheme.spacing_xl),
                Image.network(
                  'https://via.placeholder.com/150',
                  width: 150,
                  height: 150,
                ),
                const SizedBox(height: AppTheme.spacing_xl),
                TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: 'Клиент'),
                    Tab(text: 'Майстор'),
                  ],
                ),
                const SizedBox(height: AppTheme.spacing_lg),
                _buildForm(),
              ],
            ),
          ),
        ),
        tablet: Center(
          child: SizedBox(
            width: 600,
            child: Card(
              margin: const EdgeInsets.all(AppTheme.spacing_lg),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTheme.spacing_lg),
                child: Column(
                  children: [
                    Image.network(
                      'https://via.placeholder.com/150',
                      width: 150,
                      height: 150,
                    ),
                    const SizedBox(height: AppTheme.spacing_xl),
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Клиент'),
                        Tab(text: 'Майстор'),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacing_lg),
                    _buildForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
        desktop: Row(
          children: [
            Expanded(
              child: Container(
                color: AppTheme.primaryBlue,
                child: Center(
                  child: Image.network(
                    'https://via.placeholder.com/300',
                    width: 300,
                    height: 300,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 600,
                  child: Card(
                    margin: const EdgeInsets.all(AppTheme.spacing_lg),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacing_lg),
                      child: Column(
                        children: [
                          TabBar(
                            controller: _tabController,
                            tabs: const [
                              Tab(text: 'Клиент'),
                              Tab(text: 'Майстор'),
                            ],
                          ),
                          const SizedBox(height: AppTheme.spacing_lg),
                          _buildForm(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
