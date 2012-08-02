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

#include "Webkit.h"
#include "CallbackPage.h"

#ifdef __EXTENSIVE_WKHTMLTOPDF_QT_HACK__
#include "MyLooksStyle.h"
#endif

// TODO:
// 1. QWebPage::acceptNavigationRequest

int Webkit::instances = 0;
int Webkit::argc = 1;
char* Webkit::argv = { 0 };
QApplication* Webkit::application;

Webkit::Webkit( ResponseCallback rcb, MessageCallback mcb, PromptCallback pcb, BridgeCallback bcb, bool no_images, QString user_agent ){
    Webkit::instances++;
    
    bool use_graphics = true;

#ifdef __EXTENSIVE_WKHTMLTOPDF_QT_HACK__
    use_graphics = false;
    QApplication::setGraphicsSystem("raster");
#endif

    if ( !Webkit::application ) Webkit::application = new QApplication( argc, &argv, use_graphics );

#ifdef __EXTENSIVE_WKHTMLTOPDF_QT_HACK__
    Webkit::application->setStyle( new MyLooksStyle() );
#endif

    timer = new QTimer();
    page  = new CallbackPage( this, mcb, pcb, user_agent );
    frame = page->mainFrame();
    response_callback = rcb;
    bridge_callback   = bcb;

    if ( no_images ) page->settings()->setAttribute( QWebSettings::AutoLoadImages, false );
    
    frame->addToJavaScriptWindowObject( "__bridge", this );
}

Webkit::~Webkit(){
    delete page;
    delete timer;
    if ( --Webkit::instances == 0 ) {
	    Webkit::application->quit();
	    delete Webkit::application;
    }
}

void Webkit::processResponse( bool ok ){
    frame->addToJavaScriptWindowObject( "__bridge", this );

    int no_exit = 0;
    if ( this->response_callback ) no_exit = this->response_callback( this, CALLBACK_RESPONSE, ok );

    if ( !no_exit ) this->finish();
}

void Webkit::finish(){
    QObject::disconnect( frame, SIGNAL( loadFinished(bool) ), this, SLOT( processResponse(bool) ) );
    this->loop = false;
}

void Webkit::timeout() {
	this->error = ERROR_TIMEOUT;
	this->finish();
}

QString Webkit::getContent() {
    return frame->toHtml();
}

QString Webkit::getUrl(){
    return this->frame->url().toString();
}

int Webkit::get( QString url_string, unsigned int timeout ){
    frame->load( QUrl (url_string) );

    QObject::connect( frame, SIGNAL( loadFinished(bool) ), this, SLOT( processResponse(bool) ) );
    if ( timeout ) {
	    QObject::connect( timer, SIGNAL( timeout() ), this, SLOT( timeout() ) );
	    this->timer->setSingleShot(true);
	    this->timer->start(timeout);
    }

    this->loop  = true;
    this->error = 0;
    while ( this->loop ) {
	    Webkit::application->processEvents();
    }

    this->timer->stop();

    return this->error;
}

QVariant Webkit::evaluateJavaScript( QString js ) {
    return frame->evaluateJavaScript( js );
}

void Webkit::bridgeCallback(){
    if ( this->response_callback ) this->bridge_callback( this, CALLBACK_BRIDGE, (QVariant*) NULL );
}

void Webkit::bridgeCallback( QVariant arg ){
    if ( this->response_callback ) this->bridge_callback( this, CALLBACK_BRIDGE, &arg );
}
