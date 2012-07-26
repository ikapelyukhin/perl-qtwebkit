// This class is mostly copied from wkhtmltopdf (http://code.google.com/p/wkhtmltopdf/).
// It is used in graphicless mode (when using wkhtmltopdf patched fork of Qt).
//
// ----------------------------------------------------------------------------
//
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

#include <QCleanlooksStyle>
#include <QCommonStyle>
#include <QPainter>
#include <QStyleOption>

class MyLooksStyle: public QCleanlooksStyle {
public:
	typedef QCleanlooksStyle parent_t;
	
	void drawPrimitive( PrimitiveElement element, const QStyleOption * option, QPainter * painter, const QWidget * widget = 0 ) const {
		painter->setBrush(Qt::white);
		painter->setPen(QPen(Qt::black, 0.7));
		QRect r = option->rect;
		if (element == QStyle::PE_PanelLineEdit) {
			painter->drawRect(r);
		} else if(element == QStyle::PE_IndicatorCheckBox) {
			painter->drawRect(r);
			if (option->state & QStyle::State_On) {
				r.translate(r.width()*0.075, r.width()*0.075);
				painter->drawLine(r.topLeft(), r.bottomRight());
				painter->drawLine(r.topRight(), r.bottomLeft());
			}
		} else if(element == QStyle::PE_IndicatorRadioButton) {
			painter->drawEllipse(r);
			if (option->state & QStyle::State_On) {
				r.translate(r.width()*0.20, r.width()*0.20);
				r.setWidth(r.width()*0.70);
				r.setHeight(r.height()*0.70);
				painter->setBrush(Qt::black);
				painter->drawEllipse(r);
			}
		} else {
			parent_t::drawPrimitive(element, option, painter, widget);
		}
	}
};
