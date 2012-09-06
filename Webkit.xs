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

#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"
#ifdef __cplusplus
}
#endif

#include "./qtclass/Webkit.h"
#include <map>

using namespace std;

struct CALLBACK_INFO {
	SV* sv;
	SV* response;
	SV* javaScriptAlert;
	SV* javaScriptConfirm;
	SV* javaScriptConsole;
	SV* javaScriptPrompt;
	SV* bridge; // called when Webkit bridgeCallback() method is called from JavaScript 
};

static map<Webkit*, CALLBACK_INFO> reftable;

/*
	dSP;
	ENTER;
	SAVETMPS;
	
	PUSHMARK(SP);
	XPUSHs(sv_2mortal(newRV_inc( (SV*) Mapping)));
	PUTBACK;

	call_pv("dump", G_DISCARD);
	
	FREETMPS;
	LEAVE;
*/

void save_callback( Webkit*, int, SV*, SV* );
void ConvertQVariant( SV*, const QVariant* );

SV* get_callback( Webkit* wk, int callback_type ) {
	SV* sv;
	CALLBACK_INFO* ptr = &reftable[ wk ];

	switch ( callback_type ) {
		case CALLBACK_RESPONSE:           sv = ptr->response;          break;
		case CALLBACK_JAVASCRIPT_ALERT:   sv = ptr->javaScriptAlert;   break;
		case CALLBACK_JAVASCRIPT_CONFIRM: sv = ptr->javaScriptConfirm; break;
		case CALLBACK_JAVASCRIPT_CONSOLE: sv = ptr->javaScriptConsole; break;
		case CALLBACK_JAVASCRIPT_PROMPT:  sv = ptr->javaScriptPrompt;  break;
		case CALLBACK_BRIDGE:             sv = ptr->bridge;            break;
	}

	if ( sv == (SV*) NULL ) croak( "Whoops, got NULL pointer. That shouldn't have happened." );

	return sv;
}

bool call_response_callback( Webkit* instance, int callback_type, bool ok ) {
	int result;

	SV* sv = get_callback( instance, callback_type );

	if ( !SvOK( sv ) ) return 0;

	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);
	XPUSHs( reftable[ instance ].sv );
	XPUSHs( sv_2mortal( newSVsv( ok ? &PL_sv_yes : &PL_sv_no ) ) );

	PUTBACK;

	int count = call_sv( sv, G_SCALAR );
	SPAGAIN;
	
	SV* retval;
	if ( count ) retval = POPs;
	if ( count && ( SvTYPE(retval) == SVt_RV && SvTYPE( SvRV(retval) ) == SVt_PVCV ) ) {
		save_callback( instance, callback_type, reftable[instance].sv, retval );
		result = true; // Qt application event loop continues
	} else {
		save_callback( instance, callback_type, reftable[instance].sv, &PL_sv_no );
		result = false; // exit event loop
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return result;
}


void call_message_callback( Webkit* instance, int callback_type, const QString &msg, int line_number ) {
	SV* sv = get_callback( instance, callback_type );

	if ( !SvOK( sv ) ) return;

	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs( reftable[ instance ].sv );
	XPUSHs( sv_2mortal( newSVpv( msg.toUtf8().data(), msg.toUtf8().size() ) ) );
	if ( callback_type == CALLBACK_JAVASCRIPT_CONSOLE ) XPUSHs( sv_2mortal( newSViv( line_number ) ) );

	PUTBACK;
	
	call_sv( sv, G_DISCARD );

	FREETMPS;
	LEAVE;
}

bool call_prompt_callback( Webkit* instance, int callback_type, const QString& msg, const QString &default_value, QString* result_str ) {
	int count;
	bool result;

	SV* sv = get_callback( instance, callback_type );

	if ( !SvOK( sv ) ) return false;

	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs( reftable[ instance ].sv );
	XPUSHs( sv_2mortal( newSVpv( msg.toUtf8().data(), msg.toUtf8().size() ) ) );

	if ( callback_type == CALLBACK_JAVASCRIPT_PROMPT )
		XPUSHs( sv_2mortal( newSVpv( default_value.toUtf8().data(), default_value.toUtf8().size() ) ) );

	PUTBACK;
	count = call_sv( sv, G_SCALAR );
	SPAGAIN;

	if ( count == 0 ) {
		result = false;
	} else if ( callback_type == CALLBACK_JAVASCRIPT_PROMPT ) {
		SV* retval = POPs;
		if ( SvOK( retval ) && SvTYPE( retval ) == SVt_PV ) {
			result = true;
			*result_str = SvPV_nolen( retval );
		} else {
			result = false;
		}
	} else {
		SV* retval = POPs;
		result = SvTRUE( retval );
	}

	PUTBACK;
	FREETMPS;
	LEAVE;

	return result;
}

void call_bridge_callback( Webkit* instance, int callback_type, QVariant* arg ) {
	SV* sv = get_callback( instance, callback_type );

	if ( !SvOK( sv ) ) return;

	dSP;
	ENTER;
	SAVETMPS;
	PUSHMARK(SP);

	XPUSHs( reftable[ instance ].sv );
	SV* temp = sv_2mortal( newSV(0) );
	ConvertQVariant( temp, arg );
	XPUSHs( temp );

	PUTBACK;

	call_sv( sv, G_DISCARD );
	
	FREETMPS;
	LEAVE;
}

void save_callback( Webkit* instance, int callback_type, SV* blessed_ref, SV* callback ) {
	if ( SvTRUE(callback) && ( SvTYPE(callback) != SVt_RV || SvTYPE( SvRV(callback) ) != SVt_PVCV ) ) {
		croak("Supplied argument is not a code reference");
	}

	SV* ptr = get_callback( instance, callback_type );

	if ( !ptr || ptr == (SV*) NULL ) croak( "Whoops, something went terribly wrong" );
	sv_setsv( ptr, SvTRUE(callback) ? callback : &PL_sv_undef );
	sv_setsv( reftable[ instance ].sv, blessed_ref );
}

// A recursive routine to convert QVariant to corresponding Perl types
void ConvertQVariant( SV* arg, const QVariant* var ){
	if ( var == NULL ) return;
	switch ( var->type() ) {
		case QMetaType::Void:
			sv_setsv( arg, &PL_sv_undef );
			break;

		case QMetaType::Bool:
			sv_setsv( arg, var->toBool() ? &PL_sv_yes : &PL_sv_no );
			break;

		case QMetaType::Int:
			sv_setiv( arg, var->toInt() );
			break;

		case QMetaType::UInt:
			sv_setuv( arg, var->toUInt() );
			break;

		case QMetaType::Double:
			sv_setnv( arg, var->toDouble() );
			break;

		case QMetaType::QVariantMap: {
			HV* hash = newHV();
			sv_setsv( arg, sv_2mortal( newRV_noinc( (SV*) hash ) ) );

			QVariantMap* map = (QVariantMap*) var;

			QVariantMap::Iterator i = map->begin();
			while ( i != map->end() ) {
				SV* sv = newSV(0);
				hv_store( hash, i.key().toUtf8().data(), i.key().size(), sv, FALSE );
				ConvertQVariant( sv, &i.value() );
				++i;
			}
			break;
		}

		case QMetaType::QVariantList: {
			AV* av = newAV();
			sv_setsv( arg, sv_2mortal( newRV_noinc( (SV*) av ) ) );

			QVariantList* list = (QVariantList*) var;
			av_extend( av, list->size() - 1 );

			for ( int i = 0; i < list->size(); i++ ) {
				SV* sv = newSV(0);
				av_store( av, i, sv );
				ConvertQVariant( sv, &list->at(i) );
			}

			break;
		}

		case QMetaType::QString: {
			QString* str = (QString*) var;
			sv_setpvn( arg, str->toUtf8().data(), str->toUtf8().size() );
			SvUTF8_on( arg );
			break;
		}

		default:
			char buf[50];
			sprintf( buf, "Conversion for QMetaType == %u is not (yet) supported", var->type() );
			croak( buf );
			break;
	}
}

MODULE = Webkit		PACKAGE = Webkit

Webkit *
Webkit::new( ... )
	CODE:
		bool no_images = false;
		QString user_agent;

		if( items > 1 && SvROK( ST(1) ) && SvTYPE( SvRV( ST(1) ) ) == SVt_PVHV ) {
			HV* hash_ref = (HV*) SvRV( ST(1) );

			SV** temp_sv = hv_fetch( hash_ref, "NoImages", 8, 0 );
			if ( temp_sv != NULL ) no_images = SvTRUE( *temp_sv );

			temp_sv = hv_fetch( hash_ref, "UserAgent", 9, 0 );
			if ( temp_sv != NULL ) user_agent = SvPV_nolen( *temp_sv );
		}

		Webkit* wk = new Webkit(
			&call_response_callback,
			&call_message_callback,
			&call_prompt_callback,
			&call_bridge_callback,
			no_images,
			user_agent
		);

		// initially callback SVs hold undefined values
		CALLBACK_INFO obj = {
			newSV(0), // blessed_ref,
			newSV(0),
			newSV(0),
			newSV(0),
			newSV(0),
			newSV(0),
			newSV(0)
		};
		
		reftable[ wk ] = obj;
		RETVAL = wk;
	OUTPUT:
		RETVAL

void
Webkit::setResponseCallback( SV* func )
	CODE:
		save_callback( THIS, CALLBACK_RESPONSE, ST(0), func );

void
Webkit::setAlertCallback( SV* func )
	CODE:
		save_callback( THIS, CALLBACK_JAVASCRIPT_ALERT, ST(0), func );

void
Webkit::setConsoleCallback( SV* func )
	CODE:
		save_callback( THIS, CALLBACK_JAVASCRIPT_CONSOLE, ST(0), func );

void
Webkit::setConfirmCallback( SV* func )
	CODE:
		save_callback( THIS, CALLBACK_JAVASCRIPT_CONFIRM, ST(0), func );

void
Webkit::setPromptCallback( SV* func )
	CODE:
		save_callback( THIS, CALLBACK_JAVASCRIPT_PROMPT, ST(0), func );

void
Webkit::setBridgeCallback( SV* func )
	CODE:
		save_callback( THIS, CALLBACK_BRIDGE, ST(0), func );

int
Webkit::get( url_string, ... )
	QString url_string
	CODE:
		unsigned int timeout = 0;
		if( items > 2 && SvROK( ST(2) ) && SvTYPE( SvRV( ST(2) ) ) == SVt_PVHV ) {
			HV* hash_ref = (HV*) SvRV( ST(2) );
			SV** timeout_sv = hv_fetch( hash_ref, "Timeout", 7, 0 );
			if ( timeout_sv != NULL ) timeout = SvIV( *timeout_sv );
		}

		RETVAL = THIS->get( url_string, timeout );
	OUTPUT:
		RETVAL

QVariant
Webkit::evaluateJavaScript( QString js )

QString
Webkit::getUrl()

QString
Webkit::getContent()

void
Webkit::finish()

void
Webkit::DESTROY()
	CODE:
		CALLBACK_INFO* ptr = &reftable[ THIS ];
		if ( reftable[THIS].sv == (SV*) NULL ) return;

		SvREFCNT_dec( reftable[ THIS ].sv );
		SvREFCNT_dec( reftable[ THIS ].response );
		SvREFCNT_dec( reftable[ THIS ].javaScriptAlert );
		SvREFCNT_dec( reftable[ THIS ].javaScriptConfirm );
		SvREFCNT_dec( reftable[ THIS ].javaScriptConsole );
		SvREFCNT_dec( reftable[ THIS ].javaScriptPrompt );
		SvREFCNT_dec( reftable[ THIS ].bridge );

		reftable.erase( THIS );
		delete THIS;
