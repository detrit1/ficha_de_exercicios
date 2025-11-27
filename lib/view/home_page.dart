import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:ficha_de_exercicios/view/rotina_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final uid = user.uid;

    final rotinaCollection = FirebaseFirestore.instance
        .collection('rotinas')
        .doc(uid)
        .collection('minhas_rotinas');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Minhas Rotinas"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: rotinaCollection.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rotinas = snapshot.data!.docs;

          if (rotinas.isEmpty) {
            return const Center(child: Text("Nenhuma rotina cadastrada."));
          }

          return ListView.builder(
            itemCount: rotinas.length,
            itemBuilder: (context, index) {
              final rotina = rotinas[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(rotina['nome'] ?? 'Sem nome'),
                  subtitle: Text(
                      "Criada em: ${rotina['createdAt']?.toDate() ?? '---'}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await rotinaCollection.doc(rotina.id).delete();
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RotinaPage(
                          rotinaId: rotina.id,
                          rotinaNome: rotina['nome'],
                          uid: FirebaseAuth.instance.currentUser!.uid,
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
        onPressed: () => _criarNovaRotina(context, rotinaCollection),
      ),
    );
  }

  void _criarNovaRotina(
      BuildContext context, CollectionReference rotinaCollection) {
    final nomeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Nova Rotina"),
        content: TextField(
          controller: nomeController,
          decoration: const InputDecoration(labelText: "Nome da rotina"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final nome = nomeController.text.trim();
              if (nome.isNotEmpty) {
                await rotinaCollection.add({
                  'nome': nome,
                  'createdAt': Timestamp.now(),
                });
                Navigator.pop(context);
              }
            },
            child: const Text("Criar"),
          ),
        ],
      ),
    );
  }
}
