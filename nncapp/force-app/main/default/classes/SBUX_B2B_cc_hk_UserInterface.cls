/**
 * Created by dgajwani on 7/2/20.
 */

global with sharing class SBUX_B2B_cc_hk_UserInterface extends ccrz.cc_hk_UserInterface.v004 {
    private static final String FAVICON_NAME = 'SBUX_Favicon';

    global override String metaContent() {
        String ootbMeta = super.metaContent();
        // Prevent indexing on all pages.
        ootbMeta +=
                '\n <link rel="shortcut icon" type="image/x-icon" href="' + resourcePath(FAVICON_NAME, 'favicon.ico') + '"/>' +
                        '\n <link rel="shortcut icon" type="image/x-icon" sizes="16x16" href="' + resourcePath(FAVICON_NAME, 'favicon-16x16.png') + '"/>' +
                        '\n <link rel="shortcut icon" type="image/x-icon" sizes="32x32" href="' + resourcePath(FAVICON_NAME, 'favicon-32x32.png') + '"/>' +
                        '\n <link rel="shortcut icon" type="image/x-icon" sizes="96x96" href="' + resourcePath(FAVICON_NAME, 'favicon-96x96.png') + '"/>' +
                        '\n <link rel="apple-touch-icon" type="image/x-icon" sizes="57x57" href="' + resourcePath(FAVICON_NAME, 'apple-icon-57x57.png') + '"/>' +
                        '\n <link rel="apple-touch-icon" type="image/x-icon"sizes="60x60" href="' + resourcePath(FAVICON_NAME, 'apple-icon-60x60.png') + '"/>' +
                        '\n <link rel="apple-touch-icon" type="image/x-icon" sizes="72x72" href="' + resourcePath(FAVICON_NAME, 'apple-icon-72x72.png') + '"/>' +
                        '\n <link rel="apple-touch-icon" type="image/x-icon" sizes="76x76" href="' + resourcePath(FAVICON_NAME, 'apple-icon-76x76.png') + '"/>' +
                        '\n <link rel="apple-touch-icon" type="image/x-icon" sizes="114x114" href="' + resourcePath(FAVICON_NAME, 'apple-icon-114x114.png') + '"/>' +
                        '\n <link rel="apple-touch-icon" type="image/x-icon" sizes="120x120" href="' + resourcePath(FAVICON_NAME, 'apple-icon-120x120.png') + '"/>' +
                        '\n <link rel="apple-touch-icon" type="image/x-icon" sizes="144x144" href="' + resourcePath(FAVICON_NAME, 'apple-icon-144x144.png') + '"/>' +
                        '\n <link rel="apple-touch-icon" type="image/x-icon" sizes="152x152" href="' + resourcePath(FAVICON_NAME, 'apple-icon-152x152.png') + '"/>' +
                        '\n <link rel="apple-touch-icon" type="image/x-icon" sizes="180x180" href="' + resourcePath(FAVICON_NAME, 'apple-icon-180x180.png') + '"/>' +
                        '\n <link rel="icon" type="image/png" sizes="192x192" href="' + resourcePath(FAVICON_NAME, 'android-icon-192x192.png') + '"/>' +
                        '\n <link rel="manifest" href="' + resourcePath(FAVICON_NAME, 'manifest.json') + '"/>' +
                        '\n <meta name="msapplication-TileColor" content="#ffffff">' +
                        '\n <meta name="msapplication-TileImage" content="' + resourcePath(FAVICON_NAME, 'ms-icon-144x144.png') + '">' +
                        '\n <meta name="theme-color" content="#ffffff">';

        return ootbMeta;
    }
}