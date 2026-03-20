import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get_storage/get_storage.dart';
import 'package:iconly/iconly.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:vibration/vibration.dart';
import 'package:we_care/utils/colors.dart';
import 'package:we_care/utils/reusable_screen.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String email;

  const RoleSelectionScreen({super.key, required this.email});

  @override
  _RoleSelectionScreenState createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;

  void _onRoleSelected(String role) {
    setState(() {
      _selectedRole = role;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text('Select Role'),
      // ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "I am a ...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryBlack,
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () {
                      _onRoleSelected('Citizen');
                    },
                    child: Container(
                      height: 50,
                      width: 370,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.0),
                        color: _selectedRole == 'Citizen'
                            ? darkGreen
                            : const Color(0xFFf2f2f2),
                      ),
                      child: Center(
                        child: Text(
                          "Citizen",
                          style: TextStyle(
                            // fontFamily: "Poppins",
                            fontSize: 20,
                            fontWeight: _selectedRole == 'Citizen'
                                ? FontWeight.w700
                                : FontWeight.w400,
                            color: _selectedRole == 'Citizen'
                                ? primaryWhite
                                : primaryBlack,
                            height: 30 / 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      _onRoleSelected('Communities');
                    },
                    child: Container(
                      height: 50,
                      width: 370,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.0),
                        color: _selectedRole == 'Communities'
                            ? darkGreen
                            : const Color(0xFFf2f2f2),
                      ),
                      child: Center(
                        child: Text(
                          "Communities",
                          style: TextStyle(
                            // fontFamily: "Poppins",
                            fontSize: 20,
                            fontWeight: _selectedRole == 'Communities'
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _selectedRole == 'Communities'
                                ? Colors.white
                                : const Color(0xff000000),
                            height: 30 / 20,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedRole != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, size: 17),
                          SizedBox(width: 6),
                          Text(
                            "You will not be able to change this later",
                            style: TextStyle(
                              // fontFamily: "Poppins",
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: Color(0x9912121d),
                              height: 16 / 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => FormScreen(
                            email: widget.email,
                            role: _selectedRole ?? "",
                          ),
                        ),
                      ),
                      child: const CustomButton(color: darkGreen, name: "Next"),
                    ),
                    const SizedBox(height: 47),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CustomButton extends StatelessWidget {
  final String name;
  final Color color;
  const CustomButton({super.key, required this.name, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      // width: 109,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(5.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 10,
            spreadRadius: 0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Make width as wide as text
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color == darkGreen ? primaryWhite : primaryBlack,
                height: (24 / 16),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class FormScreen extends StatefulWidget {
  final String email;
  final String role;

  FormScreen({super.key, required this.email, required this.role});

  @override
  _FormScreenState createState() => _FormScreenState();
}

class _FormScreenState extends State<FormScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  final _formKey = GlobalKey<FormState>();
  final box = GetStorage();
  late String name;
  late String selectedRole;
  late String contacts;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    selectedRole = getRoleOptions().first;
  }

  List<String> getRoleOptions() {
    if (widget.role == 'Communities') {
      return ['NGO', 'NSS'];
    } else {
      return ['Citizen'];
    }
  }

  Future<File> getImageFileFromAssets(String imagePath) async {
    final byteData = await rootBundle.load(imagePath);

    final file = File(
      '${(await getTemporaryDirectory()).path}/${path.basename(imagePath)}',
    );
    await file.writeAsBytes(
      byteData.buffer.asUint8List(
        byteData.offsetInBytes,
        byteData.lengthInBytes,
      ),
    );

    return file;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('User Details Form'),
      // ),
      body: SafeArea(
        child: Material(
          color: Colors.white,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const SizedBox(height: 30),
                        SvgPicture.asset(
                          'assets/svg/doodle.svg',
                          width: 200,
                          height: 200,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          "Let’s Get to Know You",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: darkGreen,
                          ),
                        ),
                        const Text(
                          "Every story is unique, let’s begin with yours.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            // fontSize: 16,
                            // fontWeight: FontWeight.bold,
                            color: primaryBlack,
                          ),
                        ),
                        const SizedBox(height: 30),
                        TextFormField(
                          initialValue: widget.email,
                          readOnly: true,
                          style: const TextStyle(color: primaryBlack),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              IconlyBold.message,
                              color: primaryBlack,
                            ),
                            hintText: "Email",
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 10,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryGrey),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: primaryBlack),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          onSaved: (value) => name = value ?? '',
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter your name' : null,
                          style: const TextStyle(color: primaryBlack),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              IconlyBold.profile,
                              color: primaryBlack,
                            ),
                            hintText: "Name",
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 10,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryGrey),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: primaryBlack),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedRole,
                          items: getRoleOptions().map((String role) {
                            return DropdownMenuItem<String>(
                              value: role,
                              child: Text(
                                role,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: primaryBlack,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedRole = value!;
                            });
                          },
                          validator: (value) => value == null || value.isEmpty
                              ? 'Please select a role'
                              : null,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              IconlyBold.star,
                              color: primaryBlack,
                            ),
                            hintText: "Role",
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 10,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: primaryGrey),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: primaryBlack),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // CustomTextFormField(
                        //   hintText: "Contacts",
                        //   icon: IconlyBold.call,
                        //   onSaved: (value) => contacts = value ?? '',
                        //   validator: (value) =>
                        //       value!.isEmpty ? 'Please enter your contacts' : null,
                        // ),
                        Container(
                          padding: const EdgeInsets.only(left: 10),
                          child: InternationalPhoneNumberInput(
                            onInputChanged: (PhoneNumber number) {
                              String phoneNumber = number.phoneNumber ?? '';
                              print("number is : $phoneNumber");
                            },
                            selectorConfig: const SelectorConfig(
                              trailingSpace: false,
                              showFlags: true,
                              selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                              leadingPadding: 0,
                              setSelectorButtonAsPrefixIcon: false,
                            ),
                            ignoreBlank: false,
                            selectorTextStyle: const TextStyle(),
                            maxLength: 13,
                            onSaved: (value) {
                              contacts = value.toString();
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return "Please Enter your Phone number";
                              } else if (value.length < 10) {
                                return "Phone number must be at least 10 digits";
                              }
                              return null;
                            },
                            inputDecoration: InputDecoration(
                              prefixIcon: const Icon(
                                IconlyBold.call,
                                color: primaryBlack,
                              ),
                              hintText: "Phone number",
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 10,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: primaryGrey),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: primaryBlack,
                                ),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {
                        if (_formKey.currentState?.validate() ?? false) {
                          _formKey.currentState?.save();

                          final user = supabase.auth.currentUser;

                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('User not authenticated'),
                              ),
                            );
                            return;
                          }

                          final uid = user.id; // Supabase user id

                          final userData = {
                            'id': uid,
                            'profile_pic': '',
                            'description': '',
                            'name': name,
                            'address': '',
                            'contacts': contacts,
                            'email': widget.email,
                            'is_verified': "Not Applied",
                            'social_media_links': '',
                            'interests': [],
                            'role': selectedRole,
                            'issue_created': [],
                            'badges': [],
                          };

                          if (selectedRole != 'Citizen') {
                            userData.addAll({
                              'issue_resolved': [],
                              'founded_on': '',
                            });
                          }

                          // 🔥 INSERT INTO SUPABASE DB
                          await supabase.from('users').insert(userData);

                          box.write('userData', userData);

                          await _audioPlayer.setSource(
                            AssetSource('success.mp3'),
                          );
                          _audioPlayer.resume();
                          if (await Vibration.hasVibrator() != null) {
                            Vibration.vibrate(duration: 500);
                          }
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return CustomSplash(
                                  image: "assets/images/connect.svg",
                                  title: "Welcome aboard, $name",
                                  subTitle: "You're all set to ",
                                  subTitle2: "Bridge the gap",
                                  buttonName: "Get Started",
                                  nextPath: "/home",
                                );
                              },
                            ),
                          );
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 47),
                        height: 50,
                        width: 109,
                        decoration: BoxDecoration(
                          color: darkGreen,
                          borderRadius: BorderRadius.circular(5.0),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40000000),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            "Submit",
                            style: TextStyle(
                              // fontFamily: "Poppins",
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              height: (24 / 16),
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomTextFormField extends StatelessWidget {
  const CustomTextFormField({
    super.key,
    required this.hintText,
    required this.icon,
    required this.onSaved,
    required this.validator,
  });

  final String hintText;
  final IconData icon;
  final Function(String?) onSaved;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: const TextStyle(color: primaryBlack),
      cursorColor: Colors.amber,
      onSaved: onSaved,
      validator: validator,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlack, width: 0.9),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryBlack, width: 1.5),
        ),
        label: Text(
          hintText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: primaryBlack,
          ),
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Icon(icon, color: primaryBlack, size: 25),
        ),
      ),
    );
  }
}
