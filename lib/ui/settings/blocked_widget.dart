import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:event_taxi/event_taxi.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:nautilus_wallet_flutter/bus/blocked_added_event.dart';
import 'package:nautilus_wallet_flutter/bus/blocked_removed_event.dart';
import 'package:nautilus_wallet_flutter/bus/user_added_event.dart';
import 'package:nautilus_wallet_flutter/bus/user_removed_event.dart';
import 'package:nautilus_wallet_flutter/model/db/blocked.dart';
import 'package:nautilus_wallet_flutter/model/db/user.dart';
import 'package:nautilus_wallet_flutter/ui/users/add_blocked.dart';
import 'package:nautilus_wallet_flutter/ui/users/blocked_details.dart';
import 'package:nautilus_wallet_flutter/ui/users/user_details.dart';
import 'package:nautilus_wallet_flutter/ui/widgets/sheet_util.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'package:nautilus_wallet_flutter/service_locator.dart';
import 'package:nautilus_wallet_flutter/dimens.dart';
import 'package:nautilus_wallet_flutter/styles.dart';
import 'package:nautilus_wallet_flutter/app_icons.dart';
import 'package:nautilus_wallet_flutter/appstate_container.dart';
import 'package:nautilus_wallet_flutter/localization.dart';
import 'package:nautilus_wallet_flutter/bus/events.dart';
import 'package:nautilus_wallet_flutter/model/address.dart';
import 'package:nautilus_wallet_flutter/model/db/appdb.dart';
import 'package:nautilus_wallet_flutter/model/db/contact.dart';
import 'package:nautilus_wallet_flutter/ui/contacts/add_contact.dart';
import 'package:nautilus_wallet_flutter/ui/contacts/contact_details.dart';
import 'package:nautilus_wallet_flutter/ui/widgets/buttons.dart';
import 'package:nautilus_wallet_flutter/ui/util/ui_util.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flare_flutter/flare_actor.dart';

class BlockedList extends StatefulWidget {
  final AnimationController blockedController;
  bool blockedOpen;

  BlockedList(this.blockedController, this.blockedOpen);

  _BlockedListState createState() => _BlockedListState();
}

class _BlockedListState extends State<BlockedList> {
  final Logger log = sl.get<Logger>();

  List<Blocked> _blocked;
  String documentsDirectory;
  @override
  void initState() {
    super.initState();
    _registerBus();
    // Initial contacts list
    _blocked = [];
    getApplicationDocumentsDirectory().then((directory) {
      documentsDirectory = directory.path;
      setState(() {
        documentsDirectory = directory.path;
      });
      _updateContacts();
    });
  }

  @override
  void dispose() {
    if (_blockedAddedSub != null) {
      _blockedAddedSub.cancel();
    }
    if (_blockedRemovedSub != null) {
      _blockedRemovedSub.cancel();
    }
    super.dispose();
  }

  StreamSubscription<BlockedAddedEvent> _blockedAddedSub;
  StreamSubscription<BlockedRemovedEvent> _blockedRemovedSub;

  void _registerBus() {
    // Contact added bus event
    _blockedAddedSub = EventTaxiImpl.singleton().registerTo<BlockedAddedEvent>().listen((event) {
      setState(() {
        _blocked.add(event.blocked);
        //Sort by name
        _blocked.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      });
      // Full update which includes downloading new monKey
      _updateContacts();
    });
    // Contact removed bus event
    _blockedRemovedSub = EventTaxiImpl.singleton().registerTo<BlockedRemovedEvent>().listen((event) {
      setState(() {
        _blocked.remove(event.blocked);
      });
    });
  }

  void _updateContacts() {
    sl.get<DBHelper>().getBlocked().then((blocked) {
      if (blocked == null) {
        return;
      }
      for (Blocked b in blocked) {
        if (!_blocked.contains(b) && mounted) {
          setState(() {
            _blocked.add(b);
          });
        }
      }
      // Re-sort list
      setState(() {
        _blocked.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      });
    });
  }

  // Future<void> _exportContacts() async {
  //   List<User> contacts = await sl.get<DBHelper>().getBlockedUsers();
  //   if (contacts.length == 0) {
  //     UIUtil.showSnackbar(AppLocalization.of(context).noContactsExport, context);
  //     return;
  //   }
  //   List<Map<String, dynamic>> jsonList = [];
  //   contacts.forEach((contact) {
  //     jsonList.add(contact.toJson());
  //   });
  //   DateTime exportTime = DateTime.now();
  //   String filename = "nautilusblocked_${exportTime.year}${exportTime.month}${exportTime.day}${exportTime.hour}${exportTime.minute}${exportTime.second}.txt";
  //   Directory baseDirectory = await getApplicationDocumentsDirectory();
  //   File contactsFile = File("${baseDirectory.path}/$filename");
  //   await contactsFile.writeAsString(json.encode(jsonList));
  //   UIUtil.cancelLockEvent();
  //   Share.shareFile(contactsFile);
  // }

  // Future<void> _importContacts() async {
  //   UIUtil.cancelLockEvent();
  //   FilePickerResult result = await FilePicker.platform.pickFiles(allowMultiple: false, type: FileType.custom, allowedExtensions: ["txt"]);
  //   if (result != null) {
  //     File f = File(result.files.single.path);
  //     if (!await f.exists()) {
  //       UIUtil.showSnackbar(AppLocalization.of(context).contactsImportErr, context);
  //       return;
  //     }
  //     try {
  //       String contents = await f.readAsString();
  //       Iterable contactsJson = json.decode(contents);
  //       List<User> contacts = [];
  //       List<User> contactsToAdd = List();
  //       contactsJson.forEach((contact) {
  //         contacts.add(User.fromJson(contact));
  //       });
  //       for (User contact in contacts) {
  //         if (!await sl.get<DBHelper>().contactExistsWithName(contact.username) && !await sl.get<DBHelper>().userExistsWithAddress(contact.address)) {
  //           // Contact doesnt exist, make sure name and address are valid
  //           if (Address(contact.address).isValid()) {
  //             if (contact.username.startsWith("★") && contact.username.length <= 20) {
  //               contactsToAdd.add(contact);
  //             }
  //           }
  //         }
  //       }
  //       // Save all the new contacts and update states
  //       int numSaved = await sl.get<DBHelper>().saveContacts(contactsToAdd);
  //       if (numSaved > 0) {
  //         _updateContacts();
  //         EventTaxiImpl.singleton().fire(ContactModifiedEvent(contact: Contact(name: "", address: "")));
  //         UIUtil.showSnackbar(AppLocalization.of(context).contactsImportSuccess.replaceAll("%1", numSaved.toString()), context);
  //       } else {
  //         UIUtil.showSnackbar(AppLocalization.of(context).noContactsImport, context);
  //       }
  //     } catch (e) {
  //       log.e(e.toString(), e);
  //       UIUtil.showSnackbar(AppLocalization.of(context).contactsImportErr, context);
  //       return;
  //     }
  //   } else {
  //     // Cancelled by user
  //     log.e("FilePicker cancelled by user");
  //     UIUtil.showSnackbar(AppLocalization.of(context).contactsImportErr, context);
  //     return;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          color: StateContainer.of(context).curTheme.backgroundDark,
          boxShadow: [
            BoxShadow(color: StateContainer.of(context).curTheme.barrierWeakest, offset: Offset(-5, 0), blurRadius: 20),
          ],
        ),
        child: SafeArea(
          minimum: EdgeInsets.only(
            bottom: MediaQuery.of(context).size.height * 0.035,
            top: 60,
          ),
          child: Column(
            children: <Widget>[
              // Back button and Contacts Text
              Container(
                margin: EdgeInsets.only(bottom: 10.0, top: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        //Back button
                        Container(
                          height: 40,
                          width: 40,
                          margin: EdgeInsets.only(right: 10, left: 10),
                          child: FlatButton(
                              highlightColor: StateContainer.of(context).curTheme.text15,
                              splashColor: StateContainer.of(context).curTheme.text15,
                              onPressed: () {
                                setState(() {
                                  widget.blockedOpen = false;
                                });
                                widget.blockedController.reverse();
                              },
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
                              padding: EdgeInsets.all(8.0),
                              child: Icon(AppIcons.back, color: StateContainer.of(context).curTheme.text, size: 24)),
                        ),
                        //Contacts Header Text
                        Text(
                          AppLocalization.of(context).blockedHeader,
                          style: AppStyles.textStyleSettingsHeader(context),
                        ),
                      ],
                    ),
                    Row(
                      children: <Widget>[
                        // //Import button
                        // Container(
                        //   height: 40,
                        //   width: 40,
                        //   margin: EdgeInsetsDirectional.only(end: 5),
                        //   child: FlatButton(
                        //       highlightColor: StateContainer.of(context).curTheme.text15,
                        //       splashColor: StateContainer.of(context).curTheme.text15,
                        //       onPressed: () {
                        //         _importContacts();
                        //       },
                        //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
                        //       padding: EdgeInsets.all(8.0),
                        //       child: Icon(AppIcons.import_icon, color: StateContainer.of(context).curTheme.text, size: 24)),
                        // ),
                        // //Export button
                        // Container(
                        //   height: 40,
                        //   width: 40,
                        //   margin: EdgeInsetsDirectional.only(end: 20),
                        //   child: FlatButton(
                        //       highlightColor: StateContainer.of(context).curTheme.text15,
                        //       splashColor: StateContainer.of(context).curTheme.text15,
                        //       onPressed: () {
                        //         _exportContacts();
                        //       },
                        //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50.0)),
                        //       padding: EdgeInsets.all(8.0),
                        //       child: Icon(AppIcons.export_icon, color: StateContainer.of(context).curTheme.text, size: 24)),
                        // ),
                      ],
                    ),
                  ],
                ),
              ),
              // Contacts list + top and bottom gradients
              Expanded(
                child: Stack(
                  children: <Widget>[
                    // Contacts list
                    ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(top: 15.0, bottom: 15),
                      itemCount: _blocked.length,
                      itemBuilder: (context, index) {
                        // Some disaster recovery if monKey is in DB, but doesnt exist in filesystem
                        // if (_blocked[index].monkeyPath != null) {
                        //   File("$documentsDirectory/${_blocked[index].monkeyPath}").exists().then((exists) {
                        //     if (!exists) {
                        //       sl.get<DBHelper>().setMonkeyForContact(_blocked[index], null);
                        //     }
                        //   });
                        // }
                        // Build contact
                        return buildSingleContact(context, _blocked[index]);
                      },
                    ),
                    //List Top Gradient End
                    Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: 20.0,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [StateContainer.of(context).curTheme.backgroundDark, StateContainer.of(context).curTheme.backgroundDark00],
                            begin: AlignmentDirectional(0.5, -1.0),
                            end: AlignmentDirectional(0.5, 1.0),
                          ),
                        ),
                      ),
                    ),
                    //List Bottom Gradient End
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        height: 15.0,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              StateContainer.of(context).curTheme.backgroundDark00,
                              StateContainer.of(context).curTheme.backgroundDark,
                            ],
                            begin: AlignmentDirectional(0.5, -1.0),
                            end: AlignmentDirectional(0.5, 1.0),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 10),
                child: Row(
                  children: <Widget>[
                    AppButton.buildAppButton(context, AppButtonType.TEXT_OUTLINE, AppLocalization.of(context).addBlocked, Dimens.BUTTON_BOTTOM_DIMENS,
                        onPressed: () {
                      Sheets.showAppHeightNineSheet(context: context, widget: AddBlockedSheet());
                    }),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Widget buildSingleContact(BuildContext context, Blocked blocked) {
    return FlatButton(
      onPressed: () {
        BlockedDetailsSheet(blocked, documentsDirectory).mainBottomSheet(context);
      },
      padding: EdgeInsets.all(0.0),
      child: Column(children: <Widget>[
        Divider(
          height: 2,
          color: StateContainer.of(context).curTheme.text15,
        ),
        // Main Container
        Container(
          padding: EdgeInsets.symmetric(vertical: 8.0),
          margin: new EdgeInsetsDirectional.only(start: 12.0, end: 20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // natricon
              StateContainer.of(context).natriconOn
                  ? Container(
                      width: 64.0,
                      height: 64.0,
                      child: SvgPicture.network(UIUtil.getNatriconURL(blocked.address, StateContainer.of(context).getNatriconNonce(blocked.address)),
                          key: Key(UIUtil.getNatriconURL(blocked.address, StateContainer.of(context).getNatriconNonce(blocked.address))),
                          placeholderBuilder: (BuildContext context) => Container(
                                child: FlareActor(
                                  "legacy_assets/ntr_placeholder_animation.flr",
                                  animation: "main",
                                  fit: BoxFit.contain,
                                  color: StateContainer.of(context).curTheme.primary,
                                ),
                              )),
                    )
                  : SizedBox(),
              // Contact info
              Expanded(
                child: Container(
                  height: 60,
                  margin: EdgeInsetsDirectional.only(start: StateContainer.of(context).natriconOn ? 2.0 : 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Blocked name
                      Text("★" + blocked.name, style: AppStyles.textStyleSettingItemHeader(context)),

                      (blocked.username != null)
                          ? Text(
                              "@" + blocked.username,
                              style: AppStyles.textStyleTransactionAddress(context),
                            )
                          : Container(),

                      // Blocked address
                      (blocked.address != null)
                          ? Text(
                              Address(blocked.address).getShortString(),
                              style: AppStyles.textStyleTransactionAddress(context),
                            )
                          : Container(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}