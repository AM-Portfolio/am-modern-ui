import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'legal_document_page.dart';

/// In-app Privacy Policy — stays inside the app shell.
class PrivacyPolicyPage extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onOpenTerms;

  const PrivacyPolicyPage({
    this.onBack,
    this.onOpenTerms,
    super.key,
  });

  Future<void> _mail() async {
    final uri = Uri.parse('mailto:admin@asrax.in');
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    return LegalDocumentPage(
      title: 'Privacy Policy',
      lastUpdated: '14 July 2026',
      onBack: onBack,
      relatedLabel: 'Terms of Service',
      onRelatedTap: onOpenTerms,
      body: [
        LegalLead(
          'Thank you for choosing to be part of our community at AM Portfolio, '
          'doing business as Asrax and the AM Investment Platform '
          '(“AM Portfolio”, “we”, “us”, or “our”). We are committed to protecting '
          'your personal information and your right to privacy. If you have any '
          'questions or concerns about this policy or our practices, please '
          'contact us at admin@asrax.in.',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text:
                      'When you visit our website at ',
                ),
                TextSpan(
                  text: 'https://am.asrax.in',
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()
                    ..onTap = () => launchUrl(Uri.parse('https://am.asrax.in')),
                ),
                const TextSpan(
                  text:
                      ' and use our mobile application, you trust us with your '
                      'personal information. We take your privacy very seriously. '
                      'In this privacy notice, we describe our privacy policy. We '
                      'seek to explain to you in the clearest way possible what '
                      'information we collect, how we use it, and what rights you '
                      'have in relation to it. If there are any terms in this '
                      'privacy policy that you do not agree with, please '
                      'discontinue use of our Sites and our services.',
                ),
              ],
            ),
          ),
        ),
        const LegalParagraph(
          'This privacy policy applies to all information collected through our '
          'website, mobile application, and/or any related services, sales, '
          'marketing, or events (we refer to them collectively in this privacy '
          'policy as the “Sites” or “Services”).',
        ),
        const LegalParagraph(
          'Please read this privacy policy carefully as it will help you make '
          'informed decisions about sharing your personal information with us.',
        ),
        const LegalHeading('1. What information do we collect?'),
        const LegalShort(
          'We collect information you provide, information generated when you '
          'use our Services, and limited information from third parties you '
          'choose to connect.',
        ),
        const LegalSubheading('Information you provide to us'),
        LegalBulletList([
          LegalBoldItem(
            'Account information: ',
            'email address, user ID, display name, profile photo, and '
            'authentication credentials. Passwords are processed by our identity '
            'systems; we do not store plain-text passwords in the app.',
          ),
          LegalBoldItem(
            'Financial and investment information: ',
            'portfolio names, holdings, transactions, trade journal entries, '
            'metrics, templates, analytics, and documents you upload or import.',
          ),
          LegalBoldItem(
            'Subscription information: ',
            'plan, billing interval, and payment status. Payment card details '
            'are processed by payment providers; we do not store full card '
            'numbers on our servers.',
          ),
          LegalBoldItem(
            'Communications: ',
            'messages you send us for support, verification, or password recovery.',
          ),
        ]),
        const LegalSubheading('Information collected automatically'),
        LegalBulletList.strings(const [
          'Device type, operating system, app version, browser type, and diagnostic or performance data',
          'Session and navigation preferences stored on your device',
          'Authentication tokens stored in secure device storage',
          'Log and telemetry data related to app startup, errors, and service reliability',
        ]),
        const LegalSubheading('Information collected from other sources'),
        const LegalShort(
          'We may collect limited data from third-party sign-in providers and '
          'integrations you authorize.',
        ),
        const LegalParagraph(
          'We may obtain information about you from other sources, such as:',
        ),
        LegalBulletList([
          LegalBoldItem(
            'Google Sign-In: ',
            'email and basic profile information, according to permissions you grant',
          ),
          LegalBoldItem(
            'Optional integrations: ',
            'such as Gmail sync or broker-related services you connect for portfolio tracking',
          ),
          LegalBoldItem(
            'Service providers: ',
            'hosting, analytics, authentication, and payment partners that help us operate the Services',
          ),
        ]),
        const LegalHeading('2. How do we use your information?'),
        const LegalShort(
          'We process your information to provide and improve our Services based '
          'on legitimate business interests, fulfillment of our contract with '
          'you, compliance with legal obligations, and/or your consent.',
        ),
        const LegalParagraph(
          'We use personal information collected via our Sites for a variety of '
          'business purposes described below. We process your personal information '
          'for these purposes in reliance on our legitimate business interests '
          '(“Business Purposes”), in order to enter into or perform a contract '
          'with you (“Contractual”), with your consent (“Consent”), and/or for '
          'compliance with our legal obligations (“Legal Reasons”).',
        ),
        const LegalParagraph('We use the information we collect or receive:'),
        LegalBulletList([
          LegalBoldItem(
            'To facilitate account creation and logon process ',
            'with your Consent. If you link your account to a third-party account '
            '(such as Google), we use the information you allow us to collect to '
            'facilitate account creation and logon.',
          ),
          LegalBoldItem(
            'To provide our Services ',
            'for Contractual reasons, including portfolio tracking, trade '
            'journaling, market data, dashboards, document intelligence, and subscriptions.',
          ),
          LegalBoldItem(
            'To send administrative information to you ',
            'for Business Purposes, Legal Reasons and/or Contractual reasons, '
            'including changes to our terms, conditions, and policies.',
          ),
          LegalBoldItem(
            'To fulfill and manage subscriptions ',
            'for Contractual reasons, including payments and plan changes made through the Sites.',
          ),
          LegalBoldItem(
            'To protect our Sites ',
            'for Business Purposes and/or Legal Reasons, including fraud monitoring and prevention.',
          ),
          LegalBoldItem(
            'To enforce our terms, conditions and policies ',
            'for Business Purposes, Legal Reasons and/or Contractual reasons.',
          ),
          LegalBoldItem(
            'To respond to legal requests and prevent harm ',
            'for Legal Reasons.',
          ),
          LegalBoldItem(
            'For other Business Purposes, ',
            'such as data analysis, identifying usage trends, and evaluating and '
            'improving our Sites, products, services, and your experience.',
          ),
        ]),
        const LegalHeading('3. Will your information be shared with anyone?'),
        const LegalShort(
          'We only share information with your consent, to comply with laws, to '
          'protect your rights, or to fulfill business obligations. We do not '
          'sell your personal information.',
        ),
        const LegalParagraph(
          'We only share and disclose your information in the following situations:',
        ),
        LegalBulletList([
          LegalBoldItem(
            'Compliance with Laws. ',
            'We may disclose your information where we are legally required to do '
            'so to comply with applicable law, governmental requests, court orders, '
            'or legal process.',
          ),
          LegalBoldItem(
            'Vital Interests and Legal Rights. ',
            'We may disclose your information where we believe it is necessary to '
            'investigate, prevent, or take action regarding potential violations '
            'of our policies, suspected fraud, or illegal activities.',
          ),
          LegalBoldItem(
            'Vendors and Service Providers. ',
            'We may share your data with third-party vendors, service providers, '
            'contractors, or agents who perform services for us, such as hosting, '
            'authentication, payment processing, email delivery, analytics, and '
            'customer support.',
          ),
          LegalBoldItem(
            'Integrations you authorize. ',
            'When you connect Google, Gmail, or broker-related services, '
            'information is shared as required to provide those features.',
          ),
          LegalBoldItem(
            'Business Transfers. ',
            'We may share or transfer your information in connection with any '
            'merger, sale of company assets, financing, or acquisition of all or '
            'a portion of our business.',
          ),
          LegalBoldItem(
            'With your Consent. ',
            'We may disclose your personal information for any other purpose with your consent.',
          ),
        ]),
        const LegalHeading('4. Do we use cookies and other tracking technologies?'),
        const LegalShort(
          'We may use cookies and similar technologies to collect and store information.',
        ),
        const LegalParagraph(
          'We may use cookies and similar tracking technologies to access or store '
          'information on web sessions, maintain login state, and understand how '
          'our Sites are used. You can control cookies through your browser '
          'settings. Removing or rejecting cookies may affect certain features of '
          'our Sites.',
        ),
        const LegalHeading('5. How long do we keep your information?'),
        const LegalShort(
          'We keep your information for as long as necessary to fulfill the '
          'purposes outlined in this privacy policy unless otherwise required by law.',
        ),
        const LegalParagraph(
          'We will only keep your personal information for as long as it is '
          'necessary for the purposes set out in this privacy policy, unless a '
          'longer retention period is required or permitted by law. When we have '
          'no ongoing legitimate business need to process your personal '
          'information, we will either delete or anonymize it, or securely store '
          'and isolate it from further processing until deletion is possible.',
        ),
        const LegalHeading('6. How do we keep your information safe?'),
        const LegalShort(
          'We aim to protect your personal information through organizational '
          'and technical security measures.',
        ),
        const LegalParagraph(
          'We have implemented appropriate technical and organizational security '
          'measures designed to protect the security of any personal information '
          'we process, including encrypted storage for sensitive tokens on '
          'supported devices and secure API communication. However, please '
          'remember that we cannot guarantee that the internet itself is 100% '
          'secure. Transmission of personal information to and from our Sites is '
          'at your own risk.',
        ),
        const LegalHeading('7. Do we collect information from minors?'),
        const LegalShort(
          'We do not knowingly collect data from or market to children under 18 '
          'years of age.',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text:
                      'We do not knowingly solicit data from or market to children '
                      'under 18 years of age. By using the Sites, you represent '
                      'that you are at least 18. If we learn that personal '
                      'information from users less than 18 years of age has been '
                      'collected, we will deactivate the account and take '
                      'reasonable measures to promptly delete such data. Please '
                      'contact us at ',
                ),
                TextSpan(
                  text: 'admin@asrax.in',
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()..onTap = _mail,
                ),
                const TextSpan(
                  text: ' if you become aware of any such data.',
                ),
              ],
            ),
          ),
        ),
        const LegalHeading('8. What are your privacy rights?'),
        const LegalShort(
          'You may review, change, or terminate your account at any time, subject '
          'to legal and operational requirements.',
        ),
        const LegalSubheading('Account information'),
        const LegalParagraph(
          'If you would like to review or change the information in your account '
          'or terminate your account, you can:',
        ),
        LegalBulletList.strings(const [
          'Log into your account and update your profile or settings',
          'Contact us using the contact information provided below',
        ]),
        const LegalParagraph(
          'Upon your request to terminate your account, we will deactivate or '
          'delete your account and information from our active databases. However, '
          'some information may be retained to prevent fraud, troubleshoot '
          'problems, enforce our Terms of Service, and/or comply with legal '
          'requirements.',
        ),
        const LegalSubheading('Opting out of emails'),
        const LegalParagraph(
          'You can unsubscribe from marketing emails at any time by clicking the '
          'unsubscribe link in our emails or by contacting us. We may still send '
          'service-related emails necessary for administration and use of your '
          'account.',
        ),
        const LegalHeading('9. Third-party services and links'),
        const LegalParagraph(
          'The Services may link to or integrate with third-party websites and '
          'services (including Google). Their privacy practices are governed by '
          'their own policies. We encourage you to review those policies before '
          'using third-party services.',
        ),
        const LegalHeading('10. Do we make updates to this policy?'),
        const LegalShort(
          'Yes, we will update this policy as necessary to stay compliant with '
          'relevant laws.',
        ),
        const LegalParagraph(
          'We may update this privacy policy from time to time. The updated '
          'version will be indicated by an updated “Last updated” date and will '
          'be effective as soon as it is accessible. If we make material changes, '
          'we may notify you by posting a notice on our Sites or by other '
          'appropriate means. We encourage you to review this privacy policy '
          'frequently.',
        ),
        const LegalHeading('11. How can you contact us about this policy?'),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text:
                      'If you have questions or comments about this policy, you '
                      'may email us at ',
                ),
                TextSpan(
                  text: 'admin@asrax.in',
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()..onTap = _mail,
                ),
                const TextSpan(text: ' or write to us at:'),
              ],
            ),
          ),
        ),
        const LegalAddress([
          'AM Portfolio',
          'Badi Bazar, Ballialakhminia-III,',
          'Katlupur, Bihar 851211,',
          'India',
        ]),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text:
                      'If you have any further questions or comments about us or '
                      'our policies, email us at ',
                ),
                TextSpan(
                  text: 'admin@asrax.in',
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()..onTap = _mail,
                ),
                const TextSpan(text: ' or contact us at the address above.'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
