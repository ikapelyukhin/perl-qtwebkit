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

#ifndef CALLBACKPAGE_H
#define CALLBACKPAGE_H

#include <QObject>
#include <QWebPage>
#include "Webkit.h"

class CallbackPage : public QWebPage {
private:
    MessageCallback message_callback;
    PromptCallback prompt_callback;
    Webkit* wk;
    QString user_agent;
public:
    CallbackPage( Webkit* parent, MessageCallback mcb, PromptCallback pcb, QString user_agent = QString() ) : QWebPage(NULL) {
        message_callback = mcb;
        prompt_callback = pcb;
        wk = parent;
        this->user_agent = user_agent;
    }

    QString userAgentForUrl( const QUrl &url ) const {
            return user_agent.isNull() ? QWebPage::userAgentForUrl( url ) : user_agent; 
    }

    void javaScriptAlert(QWebFrame*, const QString &msg){
        if ( message_callback ) message_callback( wk, CALLBACK_JAVASCRIPT_ALERT, msg, 0 );
    }

    void javaScriptConsoleMessage(const QString &msg, int lineNumber, const QString& ){
        if ( message_callback ) message_callback( wk, CALLBACK_JAVASCRIPT_CONSOLE, msg, lineNumber );
    }

    bool javaScriptConfirm(QWebFrame*, const QString &msg){
        if ( prompt_callback ) {
            bool res = prompt_callback( wk, CALLBACK_JAVASCRIPT_CONFIRM, msg, QString(""), (QString*) NULL );
            return res;
        } else {
            return false;
        }
    }

    bool javaScriptPrompt(QWebFrame*, const QString &msg, const QString &defaultValue, QString *result){
        if ( prompt_callback ) {
            return prompt_callback( wk, CALLBACK_JAVASCRIPT_PROMPT, msg, defaultValue, result );
        } else {
            return false;
        }
    }
};

#endif // CALLBACKPAGE_H
