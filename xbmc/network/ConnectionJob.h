#pragma once
/*
 *      Copyright (C) 2005-2010 Team XBMC
 *      http://www.xbmc.org
 *
 *  This Program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2, or (at your option)
 *  any later version.
 *
 *  This Program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with XBMC; see the file COPYING.  If not, write to
 *  the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.
 *  http://www.gnu.org/copyleft/gpl.html
 *
 */

#include "system.h"
#include "IConnection.h"
#include "utils/Job.h"

class CKeyringManager;

class CConnectionJob : public CJob, public IPassphraseStorage
{
public:
  CConnectionJob(CConnectionPtr connection, CKeyringManager *keyringManager);

  virtual bool DoWork();

  virtual void InvalidatePassphrase(const std::string &uuid);
  virtual bool GetPassphrase(const std::string &uuid, std::string &passphrase);
  virtual void StorePassphrase(const std::string &uuid, const std::string &passphrase);
private:
  CConnectionPtr m_connection;
  CKeyringManager *m_keyringManager;
};