import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:auth_app/models/account.dart';
import 'package:base32/base32.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:otp/otp.dart';
import 'package:qr_bar_code_scanner_dialog/qr_bar_code_scanner_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  //Controllers
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _accTypeController = TextEditingController();
  final TextEditingController _accNameController = TextEditingController();
  final TextEditingController _setupKeyController = TextEditingController();

  //Strings
  String user = '';

  //Lists
  List<Account> accounts = [];

  //Others
  final _qrBarCodeScannerDialogPlugin = QrBarCodeScannerDialog();
  Timer? _timer;
  bool _scannedQR = false;

  @override
  void initState() {
    super.initState();
    _getName();
    _loadAccounts();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _validateSecretKey(String key) {
    try {
      base32.decode(key);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(0.1),
        child: AppBar(
          backgroundColor: Colors.black,
          flexibleSpace: Container(),
        ),
      ),
      body: Column(
        children: [
          HelloDialog(),
          SearchBar(),
          buildAccountsList(),
        ],
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            padding: EdgeInsets.only(top: 2.5, left: 3, right: 1),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(100),
              border: Border(
                bottom: BorderSide(
                  width: 0.05,
                  color: Colors.white,
                ),
                left: BorderSide(
                  width: 0.05,
                  color: Colors.white,
                ),
                right: BorderSide(
                  width: 1,
                  color: Colors.white,
                ),
                top: BorderSide(
                  width: 1,
                  color: Colors.white,
                ),
              ),
            ),
            child: FloatingActionButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                _showAddOptions(context);
              },
              shape: CircleBorder(),
              backgroundColor: Colors.white,
              child: Icon(Icons.add, color: Colors.black),
              tooltip: 'Add',
            ),
          ),
        ),
      ),
    );
  }

  Expanded buildAccountsList() {
    double screenWidth = MediaQuery.of(context).size.width;
    return Expanded(
      child: Padding(
        padding: EdgeInsets.only(left: 25, right: 25),
        child: ListView.builder(
          itemCount: accounts.length,
          itemBuilder: (context, index) {
            final account = accounts[index];

            final otpCode = OTP.generateTOTPCodeString(
              account.key,
              DateTime.now().millisecondsSinceEpoch,
              length: 6,
              interval: account.otpInterval,
              algorithm: Algorithm.SHA256,
              isGoogle: true,
            );

            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: otpCode));
                    HapticFeedback.mediumImpact();

                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   SnackBar(
                    //     width: 0.4 * screenWidth,
                    //     content: Text("Copied"),
                    //     backgroundColor: Color.fromARGB(255, 50, 50, 50),
                    //     behavior: SnackBarBehavior.floating,
                    //     shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(10),
                    //     ),
                    //   ),
                    // );
                  },
                  child: Container(
                    padding: EdgeInsets.only(top: 13, bottom: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF909090)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${account.type}: ${account.name}',
                              style: TextStyle(
                                color: Color(0xFF909090),
                                fontFamily: 'ClashDisplay',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${otpCode.substring(0, 3)} ${otpCode.substring(3, 6)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'ClashDisplay',
                                fontSize: 36,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            value: 1 -
                                (OTP.remainingSeconds() / account.otpInterval),
                            color: Color(0xFF505050),
                            backgroundColor: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                        // Text(
                        //   '${OTP.remainingSeconds()}',
                        //   style: TextStyle(
                        //     color: Colors.white,
                        //     fontFamily: 'ClashDisplay',
                        //     fontSize: 18,
                        //     fontWeight: FontWeight.w500,
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Padding SearchBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 5, bottom: 10, left: 20, right: 20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50),
          border: Border(
            top: BorderSide(
              color: Colors.white,
              width: 0.75,
            ),
            right: BorderSide(
              color: Colors.white,
              width: 0.75,
            ),
            bottom: BorderSide(
              color: Colors.white,
              width: 3, // No border
            ),
            left: BorderSide(
              color: Colors.white,
              width: 0.75, // No border
            ),
          ),
        ),
        child: TextField(
          controller: _searchController,
          keyboardAppearance: Brightness.dark,
          cursorColor: Colors.white,
          cursorWidth: 1,
          cursorHeight: 20,
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'ClashDisplay',
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            contentPadding:
                EdgeInsets.only(top: 12, bottom: 12, left: 15, right: 15),
            hintText: 'Search...',
            hintStyle: TextStyle(
              color: Color.fromRGBO(255, 255, 255, 1),
              fontFamily: 'ClashDisplay',
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            border: InputBorder.none, // Removes default border
          ),
        ),
      ),
    );
  }

  Padding HelloDialog() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.only(top: 10, bottom: 10),
            color: Colors.black,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Hello ',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'ClashDisplay',
                        fontSize: 24,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      '👋🏻',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'ClashDisplay',
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(0),
                  child: Text(
                    '${user}',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'ClashDisplay',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _getName() async {
    final prefs = await SharedPreferences.getInstance();
    user = prefs.getString('user') ?? 'User';
    setState(() {});
  }

  Future<void> _loadAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? accountsJson = prefs.getString('accounts');
    if (accountsJson != null) {
      final List<dynamic> accountsList = json.decode(accountsJson);
      setState(() {
        accounts = accountsList.map((item) => Account.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final String accountsJson =
        json.encode(accounts.map((a) => a.toJson()).toList());
    await prefs.setString('accounts', accountsJson);
  }

  void _showAddOptions(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierLabel: 'Dismiss',
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  //color: const Color.fromARGB(255, 221, 94, 94),
                  borderRadius: BorderRadius.circular(10),
                ),
                width: screenWidth * 0.85,
                height: 1.5 * (120 / 390) * screenWidth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        _accNameController.text = '';
                        _accTypeController.text = '';
                        _setupKeyController.text = '';
                        _showSetupKeyOption(context);
                      },
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: (120 / 390) * screenWidth,
                            height: (120 / 390) * screenWidth,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Image.asset(
                              'assets/icons/keyboard.png',
                              width: 62,
                              height: 62,
                            ),
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Text(
                            'Setup Key',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'ClashDisplay',
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: (35 / 390) * screenWidth,
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                        _qrBarCodeScannerDialogPlugin.getScannedQrBarCode(
                          context: context,
                          onCode: (code) {
                            if (code == null) {
                            } else {
                              if (code.split('/').length == 3 &&
                                  _validateSecretKey(code.split('/')[2])) {
                                _addAccount(code.split('/')[0],
                                    code.split('/')[1], code.split('/')[2]);
                                HapticFeedback.mediumImpact();
                              }
                            }
                          },
                        );
                      },
                      child: Column(
                        children: [
                          Container(
                            width: (120 / 390) * screenWidth,
                            height: (120 / 390) * screenWidth,
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                            child: Image.asset(
                              'assets/icons/QR.png',
                              width: 62,
                              height: 62,
                            ),
                          ),
                          SizedBox(
                            height: 15,
                          ),
                          Text(
                            'QR Code',
                            style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'ClashDisplay',
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0))
              .animate(anim), // Slide up transition
          child: child,
        );
      },
    );
  }

  void _showSetupKeyOption(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      barrierLabel: 'Dismiss',
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: EdgeInsets.only(
                  top: 10,
                  bottom: 10,
                  left: 20,
                  right: 20,
                ),
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 255, 255, 255),
                  borderRadius: BorderRadius.circular(10),
                ),
                width: screenWidth * 0.85,
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                    top: 15,
                    bottom: 15,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Type',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _accTypeController,
                          keyboardAppearance: Brightness.dark,
                          textCapitalization: TextCapitalization.words,
                          cursorColor: Color(0xFF000000),
                          cursorWidth: 1,
                          cursorHeight: 20,
                          selectionControls: DesktopTextSelectionControls(),
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                              top: 16,
                              bottom: 16,
                              left: 10,
                              right: 10,
                            ),
                            fillColor: Color(0xFFEBEBEB),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                width: 2,
                                color: (_setupKeyController.text.length > 0)
                                    ? Colors.transparent
                                    : Colors.black,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                          ),
                        ),
                        SizedBox(height: (20 / 390) * screenWidth),
                        Text(
                          'Account Name',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _accNameController,
                          keyboardAppearance: Brightness.dark,
                          cursorColor: Color(0xFF000000),
                          cursorWidth: 1,
                          cursorHeight: 20,
                          selectionControls: DesktopTextSelectionControls(),
                          style: TextStyle(
                            color: const Color.fromARGB(255, 0, 0, 0),
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                              top: 16,
                              bottom: 16,
                              left: 10,
                              right: 10,
                            ),
                            fillColor: Color(0xFFEBEBEB),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: (_accNameController.text.length > 0)
                                    ? Colors.transparent
                                    : Colors.black,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                          ),
                        ),
                        SizedBox(height: (20 / 390) * screenWidth),
                        Text(
                          'Setup Key',
                          style: TextStyle(
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: _setupKeyController,
                          keyboardAppearance: Brightness.dark,
                          cursorColor: Color(0xFF000000),
                          cursorWidth: 1,
                          cursorHeight: 20,
                          selectionControls: DesktopTextSelectionControls(),
                          style: TextStyle(
                            color: Color(0xFF000000),
                            fontFamily: 'ClashDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.only(
                              top: 16,
                              bottom: 16,
                              left: 10,
                              right: 10,
                            ),
                            fillColor: Color(0xFFEBEBEB),
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                width: 2,
                                color: (_setupKeyController.text.length > 0)
                                    ? Colors.transparent
                                    : Colors.black,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.transparent),
                            ),
                          ),
                        ),
                        SizedBox(height: 35),
                        SizedBox(
                          width: (300 / 390 * screenWidth),
                          height: 60,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_accTypeController.text.isNotEmpty &&
                                  _accNameController.text.isNotEmpty &&
                                  _setupKeyController.text.isNotEmpty) {
                                if (_validateSecretKey(
                                    _setupKeyController.text)) {
                                  _addAccount(
                                    _accTypeController.text,
                                    _accNameController.text,
                                    _setupKeyController.text,
                                  );
                                  HapticFeedback.mediumImpact();
                                  setState(() {
                                    for (var account in accounts) {
                                      account.lastOtpGenerationTime =
                                          DateTime.now().millisecondsSinceEpoch;
                                    }
                                  });
                                  Navigator.of(context).pop();
                                } else {
                                  _setupKeyController.text = '';
                                }
                              }
                            },
                            child: Text(
                              'Add',
                              style: TextStyle(
                                fontFamily: 'ClashDisplay',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: Offset(0, 1), end: Offset(0, 0))
              .animate(anim),
          child: child,
        );
      },
    );
  }

  void _addAccount(String type, String name, String setupKey) {
    setState(() {
      accounts.add(Account(
        type: type,
        name: name,
        key: setupKey,
        lastOtpGenerationTime: DateTime.now().millisecondsSinceEpoch,
      ));
      _saveAccounts();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }
}
