import 'dart:async';
import 'dart:developer';
import 'dart:io';

// import 'dart:html';
import 'dart:typed_data';

import 'package:built_collection/built_collection.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:matricular/matricular.dart';
import 'package:matricular_flutter/app/api/AppAPI.dart';
import 'package:matricular_flutter/app/utils/config_state.dart';
import 'package:matricular_flutter/routes.dart';
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

  void writeFile(Uint8List? bytes, int? fileName) async {
    final file =
        File('/storage/emulated/0/Download/${fileName}_Dados-Matricula.pdf');

    // Write the file
    file.writeAsBytesSync(bytes!);
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
        backgroundColor: Colors.blue[300],
        title: Text('Matrículas', style: TextStyle(color: Colors.white)),
        leading: IconButton(
            icon: Icon(Icons.add, color: Colors.white),
            onPressed: () {
              Routefly.navigate(routePaths.matricula.home);
            }),
        actions: [
          IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                Routefly.navigate(routePaths.login);
              })
        ],
      ),
      body: FutureBuilder<Response<BuiltList<MatriculaDTO>>>(
          future: _getData(matriculaApi),
          builder: (context,
              AsyncSnapshot<Response<BuiltList<MatriculaDTO>>> snapshot) {
            return buildListView(snapshot, context);
          }),
      bottomNavigationBar: Container(
          color: Colors.blue[300],
          child: Row(
            children: [
              IconButton(
                  icon: Icon(Icons.person, color: Colors.white),
                  onPressed: () {
                    Routefly.navigate(routePaths.matricula.home);
                  }),
              IconButton(
                  icon: Icon(Icons.chair_alt, color: Colors.white),
                  onPressed: () {
                    Routefly.navigate(routePaths.turma.list);
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
              child: Dismissible(
            key: UniqueKey(),
            direction: DismissDirection.horizontal,
            onDismissed: (DismissDirection direction) {
              if (direction == DismissDirection.endToStart) {
                matriculaControllerApi.matriculaControllerRemover(
                    id: snapshot.data!.data?[index].id ?? 0);
              }
            },
            background: const ColoredBox(
              color: Colors.orange,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(Icons.pending_rounded, color: Colors.white),
                ),
              ),
            ),
            secondaryBackground: const ColoredBox(
              color: Colors.red,
              child: Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
              ),
            ),
            confirmDismiss: (DismissDirection direction) async {
              if (direction == DismissDirection.endToStart) {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text(
                          'Tem certeza que deseja excluir a matrícula?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Não'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Sim'),
                        )
                      ],
                    );
                  },
                );
                log('Deletion confirmed: $confirmed');
                return confirmed;
              } else {
                log("editar");
              }
            },
            //height: 100,
            //width: 200,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5.0),
              ),
              color: Theme.of(context).colorScheme.inversePrimary,
              elevation: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ListTile(
                    leading: Icon(Icons.person_rounded,
                        size: 100, color: Colors.white),
                    title: Text("Nome: ${snapshot.data!.data?[index].nome}",
                        style: TextStyle(fontSize: 22.0)),
                    subtitle: Text("CPF: ${snapshot.data!.data?[index].cpf}",
                        style: TextStyle(fontSize: 18.0)),
                  ),
                  ButtonBar(
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text('Baixar matricula'),
                        onPressed: () {
                          matriculaControllerApi
                              .matriculaControllerGerarPdfDados(
                                  id: snapshot.data!.data?[index].id ?? 0)
                              .then((value) => {
                                    matriculaControllerApi
                                        .matriculaControllerGetTermo(
                                            caminhodoc:
                                                "${snapshot.data!.data?[index].id}_Dados-Matricula.pdf")
                                        .then((value) => {
                                              writeFile(
                                                  value.data,
                                                  snapshot
                                                      .data!.data?[index].id),
                                              _exibirPopupDeMensagem(context,
                                                  "${snapshot.data!.data?[index].id}_Dados-Matricula.pdf")
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
