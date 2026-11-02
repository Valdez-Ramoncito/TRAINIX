import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:trainixprogram/components/class/message_list.dart';
import 'package:trainixprogram/components/decoration/box_decoration.dart';
import 'package:trainixprogram/components/size.dart';
import 'package:trainixprogram/components/decoration/text_field.dart';

class Message extends StatefulWidget {
  const Message({super.key});

  @override
  State<Message> createState() => _MessageState();
}

class _MessageState extends State<Message> {
  final TextEditingController searchController = TextEditingController();
  String _filter = 'All';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List message = [2];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SizedBox(
                width: 400,
                child: AppTextField(
                  label: 'Search',
                  controller: searchController,
                  labelColor: Colors.grey,
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              DropdownMenu<String>(
                initialSelection: _filter,
                requestFocusOnTap: false,
                enableSearch: false,
                width: 90,
                textStyle: const TextStyle(fontSize: 13),
                inputDecorationTheme: const InputDecorationTheme(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: .5,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 205, 205, 205),
                      width: .5,
                    ),
                  ),
                ),
                onSelected: (value) {
                  setState(() {
                    _filter = value ?? 'All';
                  });
                },
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'All', label: 'All'),
                  DropdownMenuEntry(value: 'Pin', label: 'Pin'),
                ],
              ),
            ],
          ),
          const Gap(80),
          Expanded(
            child: message.isEmpty
                ? const Center(
                    child: Text(
                      "No history",
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.separated(
                    itemCount: allMessages.length,
                    separatorBuilder: (_, __) => const Gap(15),
                    itemBuilder: (_, index) {
                      var data = allMessages[index];
                      return BoxHovering(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 25),
                          child: Row(
                            mainAxisAlignment: .spaceBetween,
                            children: [
                              Row(
                                crossAxisAlignment: .center,
                                children: [
                                  CircleAvatar(
                                    radius: 25,
                                    foregroundImage: AssetImage(
                                      'assets/images/defaultProfile.png',
                                    ),
                                  ),
                                  const Gap(15),
                                  Column(
                                    mainAxisAlignment: .center,
                                    crossAxisAlignment: .start,
                                    children: [
                                      Text(
                                        data.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontSize: context.responsiveFont(
                                                6,
                                              ),
                                            ),
                                      ),
                                      Gap(10),
                                      Text(
                                        data.messageCount,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontSize: context.responsiveFont(
                                                4,
                                              ),
                                              color: const Color.fromARGB(
                                                255,
                                                210,
                                                210,
                                                210,
                                              ),
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(data.date),
                                  Gap(20),
                                  Icon(Icons.more_vert_rounded),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
