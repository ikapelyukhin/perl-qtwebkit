// This file is part of perl-qtwebkit.
//
// perl-qtwebkit is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// perl-qtwebkit is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with perl-qtwebkit. If not, see <http://www.gnu.org/licenses/>.

#ifndef WEBKIT_H
#define WEBKIT_H

#include <QApplication>
#include <QObject>
#include <QWebPage>
#include <QWebFrame>
#include <QNetworkRequest>
#include <QVariant>
#include <QMetaType>
#include <QPainter>
#include <QWebSettings>
#include <QString>
#include <QTimer>

#define CALLBACK_RESPONSE           0
#define CALLBACK_JAVASCRIPT_ALERT   1
#define CALLBACK_JAVASCRIPT_CONSOLE 2
#define CALLBACK_JAVASCRIPT_CONFIRM 3
#define CALLBACK_JAVASCRIPT_PROMPT  4
#define CALLBACK_BRIDGE             5

#define ERROR_TIMEOUT 1

class Webkit;
class CallbackPage;

typedef bool (*ResponseCallback)(Webkit*, int, bool);
typedef void ( *MessageCallback)(Webkit*, int, const QString&, int);
typedef bool (  *PromptCallback)(Webkit*, int, const QString&, const QString&, QString*);
typedef void (  *BridgeCallback)(Webkit*, int, QVariant*);

class Webkit : public QObject {
    Q_OBJECT
public:
    Webkit( ResponseCallback, MessageCallback, PromptCallback, BridgeCallback, bool no_images = false, QString user_agent = QString() );
    ~Webkit();

    QString getContent();
    QString getUrl();

    int get( QString url_string, unsigned int timeout = 0 );
    QVariant evaluateJavaScript( QString js );

    Q_INVOKABLE void bridgeCallback();
    Q_INVOKABLE void bridgeCallback( QVariant );
    Q_INVOKABLE void finish();
private:
    CallbackPage* page;
    QWebFrame* frame;
    QNetworkRequest request;
    ResponseCallback response_callback;
    BridgeCallback bridge_callback;
    
    bool loop;
    int error;
    QTimer* timer;

    static int instances;
    // For any GUI application using Qt, there is precisely one QApplication object, no matter whether the application
    // has 0, 1, 2 or more windows at any given time.
    static QApplication* application;

    // must stay valid for the entire lifetime of the QApplication object.
    static int argc;   // must be greater than zero
    static char* argv; // must contain at least one valid character string.

private slots:
    void processResponse( bool ok );
    void timeout();
signals:
    void finished();
};

#endif // WEBKIT_H
