import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'legal_document_page.dart';

/// In-app Terms of Service — stays inside the app shell.
class TermsOfServicePage extends StatelessWidget {
  final VoidCallback? onBack;
  final VoidCallback? onOpenPrivacy;

  const TermsOfServicePage({
    this.onBack,
    this.onOpenPrivacy,
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
      title: 'Terms of Service',
      lastUpdated: '14 July 2026',
      onBack: onBack,
      relatedLabel: 'Privacy Policy',
      onRelatedTap: onOpenPrivacy,
      body: [
        const LegalHeading('Welcome to AM Investment Platform'),
        LegalLead(
          'Thanks for using our products and services (“Services”). The Services '
          'are provided by AM Portfolio, doing business as Asrax, through its '
          'network of websites and domains at am.asrax.in and related mobile '
          'applications (“Site”).',
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text:
                      'By using our Services, you are agreeing to these terms. '
                      'Please read them carefully. These Terms should be read '
                      'together with our ',
                ),
                TextSpan(
                  text: 'Privacy Policy',
                  style: linkStyle,
                  recognizer: onOpenPrivacy == null
                      ? null
                      : (TapGestureRecognizer()..onTap = onOpenPrivacy),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ),
        const LegalHeading('Terms'),
        const LegalParagraph(
          'By accessing the Site, you agree to be bound by these terms of '
          'service, all applicable laws and regulations, and agree that you are '
          'responsible for compliance with any applicable local laws. If you do '
          'not agree with any of these terms, you are prohibited from using or '
          'accessing this Site. The materials contained in this website are '
          'protected by applicable copyright and trademark law.',
        ),
        const LegalParagraph(
          'You must be at least 18 years old and able to form a binding contract '
          'to use the Services. You are responsible for maintaining the '
          'confidentiality of your account credentials and for all activity under '
          'your account.',
        ),
        const LegalHeading('Service description'),
        const LegalParagraph(
          'AM Investment Platform provides portfolio tracking, trade journaling, '
          'market data, analytics, document intelligence, and related investment '
          'tools for informational and record-keeping purposes. We are not a '
          'broker, dealer, or investment adviser. We do not execute buy or sell '
          'orders, hold client funds or securities, or provide personalized '
          'investment advice through the Services.',
        ),
        const LegalHeading('Service License'),
        const LegalParagraph(
          'Permission is granted to use the materials (information or software) '
          'on the Site for personal, non-commercial transitory viewing only. This '
          'is the grant of a license, not a transfer of title, and under this '
          'license you may not:',
        ),
        LegalBulletList.strings(const [
          'modify or copy the materials;',
          'use the materials for any commercial purpose, or for any public display (commercial or non-commercial);',
          'attempt to decompile or reverse engineer any software contained on the Site;',
          'remove any copyright or other proprietary notations from the materials; or',
          'transfer the materials to another person or “mirror” the materials on any other server.',
        ]),
        const LegalParagraph(
          'This license shall automatically terminate if you violate any of these '
          'restrictions and may be terminated by us at any time. Upon terminating '
          'your viewing of these materials or upon the termination of this '
          'license, you must destroy any downloaded materials in your possession '
          'whether in electronic or printed format.',
        ),
        const LegalHeading('Acceptable use'),
        const LegalParagraph(
          'You agree not to misuse the Services, attempt unauthorized access, '
          'interfere with platform operation, upload unlawful content, scrape or '
          'overload our systems, or use the Services in violation of applicable '
          'law, including securities and financial regulations.',
        ),
        const LegalHeading('Subscriptions and payments'),
        const LegalParagraph(
          'Paid features, if offered, are subject to the pricing and billing '
          'terms shown at purchase. Fees may renew automatically unless cancelled '
          'according to the plan terms. Payment processing may be handled by '
          'third-party providers.',
        ),
        const LegalHeading('Disclaimer and Warranties'),
        const LegalParagraph(
          'The materials on the Site are provided on an ‘as is’ basis. We make no '
          'warranties, expressed or implied, and hereby disclaim and negate all '
          'other warranties including, without limitation, implied warranties or '
          'conditions of merchantability, fitness for a particular purpose, or '
          'non-infringement of intellectual property or other violation of rights.',
        ),
        const LegalParagraph(
          'Market data, portfolio information, analytics, and other content may '
          'be sourced from third parties and automated systems. These are prone '
          'to delay, omission, or error. We are not responsible for the accuracy, '
          'reliability, performance, completeness, currentness, functionality, '
          'continuity, or timeliness of the information, data, or any content '
          'available through the Services.',
        ),
        const LegalParagraph(
          'Though we make best efforts for accuracy, the materials appearing on '
          'the Site could include technical, typographical, or other errors. We '
          'do not warrant that any of the materials on the Site are accurate, '
          'complete, or current. We may make changes to the materials contained '
          'on the Site at any time without notice.',
        ),
        const LegalParagraph(
          'Investment disclaimer: Nothing on the Site constitutes investment '
          'advice, a recommendation, or an offer to buy or sell any security or '
          'financial product. Equity and market investments are subject to market '
          'risks. You are solely responsible for your investment decisions. Please '
          'read all related documents carefully and consult your financial '
          'adviser before investing.',
        ),
        const LegalParagraph(
          'Further, we do not warrant or make any representations concerning the '
          'accuracy, likely results, or reliability of the use of the materials '
          'on its website or otherwise relating to such materials or on any sites '
          'linked to this Site.',
        ),
        const LegalHeading('Liability for our Services'),
        const LegalParagraph(
          'WE, AM PORTFOLIO, WILL NOT BE RESPONSIBLE FOR LOST PROFITS, REVENUES '
          'OR DATA, FINANCIAL LOSSES OR INDIRECT, SPECIAL, CONSEQUENTIAL, '
          'EXEMPLARY OR PUNITIVE DAMAGES.',
        ),
        const LegalParagraph(
          'THE TOTAL LIABILITY OF THE SITE FOR ANY CLAIMS UNDER THESE TERMS, '
          'INCLUDING FOR ANY IMPLIED WARRANTIES, IS LIMITED TO THE AMOUNT THAT '
          'YOU PAID US TO USE THE SERVICES (IF ANY) IN THE TWELVE (12) MONTHS '
          'PRECEDING THE CLAIM.',
        ),
        const LegalParagraph(
          'IN ALL CASES, WE WILL NOT BE LIABLE FOR ANY LOSS OR DAMAGE THAT ARISES '
          'FROM THE USAGE OF THE SITE OR RELIANCE ON INFORMATION PROVIDED THROUGH '
          'THE SERVICES.',
        ),
        const LegalHeading('Links'),
        const LegalParagraph(
          'We have not reviewed all of the links present on the Site and are not '
          'responsible for the contents of any such linked website. The inclusion '
          'of any link does not imply our endorsement. Use of any such linked '
          'website is at the user’s own risk.',
        ),
        const LegalHeading('Modifications'),
        const LegalParagraph(
          'These terms of service may be updated from time to time. We will update '
          'the “Last updated” date to alert about the changes. It is your '
          'responsibility to periodically review these changes and stay informed '
          'about the updates. By using this website you are agreeing to be bound '
          'by the then current version of these terms of service.',
        ),
        const LegalHeading('Governing Law'),
        const LegalParagraph(
          'These terms and conditions are governed by and construed in accordance '
          'with the laws of India and you irrevocably submit to the exclusive '
          'jurisdiction of the courts in Bihar, India.',
        ),
        const LegalHeading('Contact Us'),
        const LegalParagraph(
          'In order to resolve a complaint regarding the Site or to receive '
          'further information regarding use of the Site, please contact us at:',
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
                TextSpan(
                  text: 'admin@asrax.in',
                  style: linkStyle,
                  recognizer: TapGestureRecognizer()..onTap = _mail,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
