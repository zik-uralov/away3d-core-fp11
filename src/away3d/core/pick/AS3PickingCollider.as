package away3d.core.pick
{
	import away3d.core.base.*;
	
	import flash.geom.*;


	public class AS3PickingCollider extends PickingColliderBase implements IPickingCollider
	{
		// TODO: implement find best hit
		private var _findBestHit:Boolean;

		private var i:uint;
		private var t:Number;
		private var numTriangles:uint;
		private var i0:uint, i1:uint, i2:uint;
		private var rx:Number, ry:Number, rz:Number;
		private var nx:Number, ny:Number, nz:Number;
		private var cx:Number, cy:Number, cz:Number;
		private var coeff:Number, u:Number, v:Number, w:Number;
		private var p0x:Number, p0y:Number, p0z:Number;
		private var p1x:Number, p1y:Number, p1z:Number;
		private var p2x:Number, p2y:Number, p2z:Number;
		private var s0x:Number, s0y:Number, s0z:Number;
		private var s1x:Number, s1y:Number, s1z:Number;
		private var nl:Number, nDotV:Number, D:Number, disToPlane:Number;
		private var Q1Q2:Number, Q1Q1:Number, Q2Q2:Number, RQ1:Number, RQ2:Number;
		
		public function AS3PickingCollider( findBestHit:Boolean = false )
		{
			_findBestHit = findBestHit;
		}
		
		public function testSubMeshCollision(subMesh:SubMesh, pickingCollisionVO:PickingCollisionVO):Boolean
		{
			
			var indexData:Vector.<uint> = subMesh.indexData;
			var vertexData:Vector.<Number> = subMesh.vertexData;
			var uvData:Vector.<Number> = subMesh.UVData;
			numTriangles = subMesh.numTriangles;
			
			for( i = 0; i < numTriangles; ++i ) { // sweep all triangles

				var index:uint = i * 3;

				// evaluate triangle indices
				i0 = indexData[ index ] * 3;
				i1 = indexData[ index + 1 ] * 3;
				i2 = indexData[ index + 2 ] * 3;

				// evaluate triangle vertices
				p0x = vertexData[ i0 ];
				p0y = vertexData[ i0 + 1 ];
				p0z = vertexData[ i0 + 2 ];
				p1x = vertexData[ i1 ];
				p1y = vertexData[ i1 + 1 ];
				p1z = vertexData[ i1 + 2 ];
				p2x = vertexData[ i2 ];
				p2y = vertexData[ i2 + 1 ];
				p2z = vertexData[ i2 + 2 ];

				// evaluate sides and triangle normal
				s0x = p1x - p0x; // s0 = p1 - p0
				s0y = p1y - p0y;
				s0z = p1z - p0z;
				s1x = p2x - p0x; // s1 = p2 - p0
				s1y = p2y - p0y;
				s1z = p2z - p0z;
				nx = s0y * s1z - s0z * s1y; // n = s0 x s1
				ny = s0z * s1x - s0x * s1z;
				nz = s0x * s1y - s0y * s1x;
				nl = 1 / Math.sqrt( nx * nx + ny * ny + nz * nz ); // normalize n
				nx *= nl;
				ny *= nl;
				nz *= nl;

				// -- plane intersection test --
				nDotV = nx * rayDirection.x + ny * + rayDirection.y + nz * rayDirection.z; // rayDirection . normal
				if( nDotV < 0 ) { // an intersection must exist
					// find collision t
					D = -( nx * p0x + ny * p0y + nz * p0z );
					disToPlane = -( nx * rayPosition.x + ny * rayPosition.y + nz * rayPosition.z + D );
					t = disToPlane / nDotV;
					// find collision point
					cx = rayPosition.x + t * rayDirection.x;
					cy = rayPosition.y + t * rayDirection.y;
					cz = rayPosition.z + t * rayDirection.z;
					// collision point inside triangle? ( using barycentric coordinates )
					Q1Q2 = s0x * s1x + s0y * s1y + s0z * s1z;
					Q1Q1 = s0x * s0x + s0y * s0y + s0z * s0z;
					Q2Q2 = s1x * s1x + s1y * s1y + s1z * s1z;
					rx = cx - p0x;
					ry = cy - p0y;
					rz = cz - p0z;
					RQ1 = rx * s0x + ry * s0y + rz * s0z;
					RQ2 = rx * s1x + ry * s1y + rz * s1z;
					coeff = 1 / ( Q1Q1 * Q2Q2 - Q1Q2 * Q1Q2 );
					v = coeff * ( Q2Q2 * RQ1 - Q1Q2 * RQ2 );
					w = coeff * ( -Q1Q2 * RQ1 + Q1Q1 * RQ2 );
					if( v < 0 ) continue;
					if( w < 0 ) continue;
					u = 1 - v - w;
					if( !( u < 0 ) ) { // all tests passed
						pickingCollisionVO.collisionT = t;
						pickingCollisionVO.localPosition = new Vector3D( cx, cy, cz );
						pickingCollisionVO.localNormal = new Vector3D( nx, ny, nz );
						pickingCollisionVO.uv = getCollisionUV( indexData, uvData, index, v, w, u );
						
						// does not search for closest collision, first found will do... // TODO: add option of finding best triangle hit?
						return true;
					}
				}
			}
			
			return false;
		}
	}
}
