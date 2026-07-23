import 'package:get_it/get_it.dart';

final sl = GetIt.instance; // sl is service locator

Future<void> init() async {
  // Features - Project Analysis
  // Bloc / Provider
  // sl.registerFactory(() => ProjectAnalysisProvider(sl()));

  // Use cases
  // sl.registerLazySingleton(() => AnalyzeProjectUseCase(sl()));

  // Repository
  // sl.registerLazySingleton<ProjectAnalysisRepository>(
  //   () => ProjectAnalysisRepositoryImpl(localDataSource: sl()),
  // );

  // Data sources
  // sl.registerLazySingleton<ProjectAnalysisLocalDataSource>(
  //   () => ProjectAnalysisLocalDataSourceImpl(),
  // );

  // Core
  // sl.registerLazySingleton<NetworkInfo(() => NetworkInfoImpl(sl()));

  // External / Services
  // sl.registerLazySingleton(() => FileSystemService());
}
