// Openapi Generator last run: : 2024-05-04T15:15:35.140063
import 'package:openapi_generator_annotations/openapi_generator_annotations.dart';
//dart run build_runner build  --delete-conflicting-outputs -v
@Openapi(
  additionalProperties: DioProperties(pubName: 'matricular', pubAuthor: 'Lucas'),
  inputSpec: InputSpec(path: 'matricularapi/api-docs.json'),
  //typeMappings: {'Pet': 'ExamplePet'},
  generatorName: Generator.dio,
  runSourceGenOnOutput: true,
  outputDirectory: 'matricularapi',
)
class OpenApigenerator {}