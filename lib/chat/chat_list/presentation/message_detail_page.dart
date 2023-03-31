import 'package:flutter_chat_research/chat/models/message.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter/material.dart';
import '../../../auth/models/user.dart';
import '../../../core/utils/firebase_function.dart';

class MessageDetailPage extends ConsumerStatefulWidget {
  const MessageDetailPage(this.message, this.controller, {super.key});

  final Message message;
  final ScrollController controller;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _MessageDetailPageState();
}

class _MessageDetailPageState extends ConsumerState<MessageDetailPage> {
  List<User> userList = [];
  @override
  void initState() {
    super.initState();
    getReceiverUser();
  }

  getReceiverUser() async {
    for (var element in widget.message.receiverIds) {
      var user = await getUser(element);
      userList.add(user!);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Seen Users'),
        Expanded(
          child: SingleChildScrollView(
            controller: widget.controller,
            child: Column(
              children: List.generate(
                  // 30,
                  userList.length,
                  (index) => Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 100),
                        child: Text(userList[index].name),
                      )),
            ),
          ),
        ),
      ],
    );
    // return ListView.builder(
    //   controller: widget.controller,
    //   itemCount: 30,
    //   physics: AlwaysScrollableScrollPhysics(),
    //   // itemCount: widget.message.receiverIds.length,
    //   itemBuilder: (context, index) => Padding(
    //     padding: const EdgeInsets.all(18.0),
    //     child: Text(widget.message.receiverIds[0]),
    //   ),
    // );
  }
}
