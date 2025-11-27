import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'form_exercicio_page.dart';
import 'package:ficha_de_exercicios/model/exercicio.dart';

class RotinaPage extends StatelessWidget {
  final String rotinaId;
  final String rotinaNome;
  final String uid;

  const RotinaPage({
    super.key,
    required this.rotinaId,
    required this.rotinaNome,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final exerciciosCollection = FirebaseFirestore.instance
        .collection('rotinas')
        .doc(uid)
        .collection('minhas_rotinas')
        .doc(rotinaId)
        .collection('exercicios');

    return Scaffold(
      appBar: AppBar(
        title: Text("Rotina: $rotinaNome"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: exerciciosCollection.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(child: Text("Nenhum exercício cadastrado."));
          }

          // Converte cada DocumentSnapshot em Exercicio
          final exercicios = docs.map((doc) => Exercicio.fromFirestore(doc)).toList();

          return ListView.builder(
            itemCount: exercicios.length,
            itemBuilder: (context, index) {
              final ex = exercicios[index];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(ex.nome),
                  subtitle: Text(
                      "Séries: ${ex.series} x Repetições: ${ex.repeticoes} • Carga: ${ex.carga} kg"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () async {
                      if (ex.id != null) {
                        await exerciciosCollection.doc(ex.id).delete();
                      }
                    },
                  ),
                  onTap: () async {
                    // Editar exercício existente
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FormExercicioPage(
                          uid: uid,
                          rotinaId: rotinaId,
                          exercicio: ex,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          // Criar novo exercício
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FormExercicioPage(
                uid: uid,
                rotinaId: rotinaId,
              ),
            ),
          );
        },
      ),
    );
  }
}
