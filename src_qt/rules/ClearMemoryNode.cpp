#include "ClearMemoryNode.h"
#include "../Brain.h"

namespace CnotiMind
{

	ClearMemoryNode::ClearMemoryNode( const MemoryType& memory, Brain* brain, QObject* parent ) :
		RuleNode(brain, parent),
		_memory( memory )
	{
	}


	void ClearMemoryNode::exec()
	{
		switch( _memory )
		{
		case LongTermMemory:
			_brain->clearMemory();
			break;
		case WorkingMemory:
			_brain->clearWorkingMemory();
			break;
		}
	}

	void ClearMemoryNode::exec( QHash<QString, QString>& variables )
	{
		Q_UNUSED( variables )

		exec();
	}

	QString ClearMemoryNode::info( int depth ) const
	{
		return space( depth ) + "ClearMemory (" + (_memory == LongTermMemory ? "LTM" : "WM" ) + ")";
	}

}
