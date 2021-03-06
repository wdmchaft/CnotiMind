#include "RandomNode.h"
#include "../Brain.h"

namespace CnotiMind
{

	RandomNode::RandomNode(Brain* brain, QObject *parent) :
		RuleNode(brain, parent)
	{
	}

	/**
		Choose a random child node and executes it.
	*/
	void RandomNode::exec()
	{
		int count = children().size();

		// It must have children nodes to run
		if(count == 0)
		{
			return;
		}

		int n = qrand() % count;

		RuleNode* node = (RuleNode* ) children().value( n );

		node->exec();

	}

	void RandomNode::exec( QHash<QString, QString>& variables )
	{
		int count = children().size();

		// It must have children nodes to run
		if(count == 0)
		{
			return;
		}

		int n = qrand() % count;

		RuleNode* node = ( RuleNode* ) children().at( n );
		node->exec( variables );
	}

	QString RandomNode::info( int depth ) const
	{
		return space( depth ) + "Random";
	}
}
