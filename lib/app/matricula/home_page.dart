import 'dart:async';
// import 'dart:html';
import 'dart:typed_data';
import 'dart:io';

import 'package:built_collection/built_collection.dart';
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:matricular/matricular.dart';
import 'package:matricular_flutter/app/api/AppAPI.dart';
import 'package:matricular_flutter/app/utils/config_state.dart';
import 'package:matricular_flutter/routes.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:routefly/routefly.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  static Route<void> route() {
    return MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MultiProvider(
              providers: [
                Provider(
                  create: (_) => context.read<ConfigState>(),
                  dispose: (_, instance) => instance.dispose(),
                ),
                Provider(create: (_) => context.read<AppAPI>())
              ],
              child: const StartPage(),
            ));
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/termo-responsabilidade.pdf');
  }

  void writeFile(Uint8List? bytes, String? fileName) async {
    final file = await _localFile;

    // Write the file
     file.writeAsBytesSync(bytes!);
     saveFile("termo-responsabilidade-$fileName.pdf");
  }

  Future<void> saveFile(String fileName) async {
    var file = File('');
    final filePath = await _localPath;

    // Platform.isIOS comes from dart:io
    if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      file = File('${dir.path}/$fileName');
    }
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        status = await Permission.storage.request();
      }
      if (status.isGranted) {
        const downloadsFolderPath = '/storage/emulated/0/Download/';
        Directory dir = Directory(downloadsFolderPath);
        file = File('${dir.path}/$fileName');
      }
    }
    final byteData = await rootBundle.load("$filePath/termo-responsabilidade.pdf");
    try {
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    } on FileSystemException catch (err) {
      // handle error
    }
  }

  Future<Response<BuiltList<MatriculaDTO>>> _getData(
      MatriculaControllerApi matriculaApi) async {
    try {
      var dado = await matriculaApi.matriculaControllerListAll();
      return dado;
    } on DioException catch (e) {
      debugPrint("Erro home:" + e.response.toString());
      return Future.value([] as FutureOr<Response<BuiltList<MatriculaDTO>>>?);
    }
  }

  void _exibirPopupDeMensagem(BuildContext context, String fileName) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Download'),
          content: Text('Download do arquivo $fileName realizado com sucesso.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                // Fechar o popup
                Navigator.of(context).pop();
              },
              child: Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    MatriculaControllerApi? matriculaApi =
        context.read<AppAPI>().api.getMatriculaControllerApi();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('Home da aplicação '),
      ),
      body: FutureBuilder<Response<BuiltList<MatriculaDTO>>>(
          future: _getData(matriculaApi),
          builder: (context,
              AsyncSnapshot<Response<BuiltList<MatriculaDTO>>> snapshot) {
            return buildListView(snapshot, context);
          }),
      bottomNavigationBar: Container(
          color: Colors.blue,
          child: Row(
            children: [
              IconButton(
                  icon: Icon(Icons.home),
                  onPressed: () {
                    Routefly.navigate(routePaths.login);
                  })
            ],
          )),
    );
  }

  Widget buildListView(
      AsyncSnapshot<Response<BuiltList<MatriculaDTO>>> snapshot,
      BuildContext context) {
    MatriculaControllerApi? matriculaControllerApi =
        context.read<AppAPI>().api.getMatriculaControllerApi();
    if (snapshot.hasData) {
      return ListView.builder(
        itemCount: snapshot.data?.data?.length,
        itemBuilder: (BuildContext context, int index) {
          return Center(
              child: Container(
            //height: 100,
            //width: 200,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15.0),
              ),
              color: Colors.blue.withAlpha(70),
              elevation: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.account_box, size: 60),
                    title: Text("nome: ${snapshot.data!.data?[index].nome}",
                        style: TextStyle(fontSize: 22.0)),
                    subtitle: Text("CPF: ${snapshot.data!.data?[index].cpf}",
                        style: TextStyle(fontSize: 18.0)),
                  ),
                  ButtonBar(
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text('Gerar Termo'),
                        onPressed: () {
                          matriculaControllerApi
                              .matriculaControllerGerarTermo(
                                  id: snapshot.data!.data?[index].id ?? 0,
                                  cpfTutor: snapshot.data!.data?[index]
                                          .responsaveis?.first.cpfResponsavel ??
                                      "")
                              .then((value) => {
                                    matriculaControllerApi
                                        .matriculaControllerGetTermo(
                                            caminhodoc:
                                                "Termo-Responsabilidade-${snapshot.data!.data?[index].cpf ?? ""}.pdf").then((value) => {
                                                  writeFile(value.data, snapshot.data!.data?[index].cpf),
                                                  _exibirPopupDeMensagem(context, "termo-responsabilidade-${snapshot.data!.data?[index].cpf}.pdf")
                                    })
                                  });
                        },
                      )
                    ],
                  ),
                ],
              ),
            ),
          ));
        },
      );
    } else if (snapshot.hasError) {
      Routefly.navigate(routePaths.login);
      return Text('Erro ao acessar dados');
    } else {
      return CircularProgressIndicator();
    }
  }

  Text buildItemList(
      AsyncSnapshot<Response<BuiltList<MatriculaDTO>>> snapshot, int index) {
    return Text("nome:${snapshot.data!.data?[index]}");
  }
}
