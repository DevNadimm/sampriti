import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sampriti/core/shared/themes/theme.dart';
import 'package:sampriti/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:sampriti/features/auth/presentation/pages/splash_page.dart';
import 'package:sampriti/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:sampriti/features/finance/presentation/bloc/bank_bloc.dart';
import 'package:sampriti/features/members/presentation/bloc/member_bloc.dart';
import 'package:sampriti/features/setup/presentation/bloc/project_bloc.dart';
import 'package:sampriti/features/setup/presentation/bloc/sector_bloc.dart';
import 'package:sampriti/features/transactions/presentation/bloc/transaction_bloc.dart';
import 'package:sampriti/main.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()),
        BlocProvider(create: (_) => DashboardBloc()),
        BlocProvider(create: (_) => MemberBloc()),
        BlocProvider(create: (_) => TransactionBloc()),
        BlocProvider(create: (_) => ProjectBloc()),
        BlocProvider(create: (_) => SectorBloc()),
        BlocProvider(create: (_) => BankBloc()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'সম্প্রীতি ইনভেস্টমেন্ট ফোরাম',
        theme: theme,
        home: const SplashPage(),
      ),
    );
  }
}
